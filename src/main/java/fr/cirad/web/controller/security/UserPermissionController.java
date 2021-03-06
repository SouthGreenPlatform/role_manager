/*******************************************************************************
 * Role Manager - Generic web tool for managing user roles using Spring Security
 * Copyright (C) 2018, <CIRAD>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License, version 3 as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * See <http://www.gnu.org/licenses/agpl.html> for details about GNU General
 * Public License V3.
 *******************************************************************************/
package fr.cirad.web.controller.security;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.lang.reflect.InvocationTargetException;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.ResourceBundle;
import java.util.ResourceBundle.Control;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import javax.servlet.http.HttpServletRequest;

import org.apache.commons.collections.CollectionUtils;
import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.GrantedAuthorityImpl;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import fr.cirad.security.ReloadableInMemoryDaoImpl;
import fr.cirad.security.base.IModuleManager;
import fr.cirad.security.base.IRoleDefinition;

@Controller
public class UserPermissionController
{
	private static final Logger LOG = Logger.getLogger(UserPermissionController.class);

	static final public String FRONTEND_URL = "private/roleManager";

	static final public String userListPageURL = "/" + FRONTEND_URL + "/UserList.do_";
	static final public String userListDataURL = "/" + FRONTEND_URL + "/listUsers.json_";
	static final public String userListCountURL = "/" + FRONTEND_URL + "/countUsers.json_";
	static final public String userRemovalURL = "/" + FRONTEND_URL + "/removeUser.json_";
	static final public String userDetailsURL = "/" + FRONTEND_URL + "/UserDetails.do_";
	static final public String userPermissionURL = "/" + FRONTEND_URL + "/UserPermissions.do_";

	public static final String LEVEL1 = "LEVEL1";
	public static final String LEVEL1_ROLES = "LEVEL1_ROLES";
	public static final String ROLE_STRING_SEPARATOR = "$";

	public static final HashMap<String, LinkedHashSet<String>> rolesByLevel1Type = new HashMap<>();

	@Autowired private IModuleManager moduleManager;
	@Autowired private ReloadableInMemoryDaoImpl userDao;

    private static Control resourceControl = new ResourceBundle.Control() {
        @Override
        public boolean needsReload(String baseName, java.util.Locale locale, String format, ClassLoader loader, ResourceBundle bundle, long loadTime) {
            return true;
        }

        @Override
        public long getTimeToLive(String baseName, java.util.Locale locale) {
            return 0;
        }
    };
    
    static
    {
		ResourceBundle bundle = ResourceBundle.getBundle("roles", resourceControl);
		String level1EntityTypes = "";
		try
		{
			level1EntityTypes = bundle.getString(LEVEL1);
		}
		catch (Exception e)
		{
			LOG.warn("No entity types found to manage permissions for in roles.properties (you may specify some by adding a LEVEL1 property with comma-separated strings as a value)");
		}
        String[] level1Types = StringUtils.tokenizeToStringArray(level1EntityTypes, ",");
        for (String level1Type : level1Types)
        	try
        	{
        		LinkedHashSet levelRoles = new LinkedHashSet();
        		levelRoles.add(IRoleDefinition.ENTITY_MANAGER_ROLE);	// this one must exist even if not declared in roles.properties
        		levelRoles.addAll(Arrays.asList(StringUtils.tokenizeToStringArray(bundle.getString(LEVEL1_ROLES + "_" + level1Type), ",")));
        		rolesByLevel1Type.put(level1Type, levelRoles);
        	}
			catch (Exception e)
			{
				LOG.warn("No roles to manage " + level1Type + " entities in roles.properties (you may specify some by adding a LEVEL1_ROLES_" + level1Type + " property with comma-separated strings as a value)");
			}
    }

	@RequestMapping(userListPageURL)
	protected ModelAndView setupList() throws Exception
	{
		return new ModelAndView();
    }

	@RequestMapping(userListCountURL)
	protected @ResponseBody int countUsersByLoginLookup(@RequestParam("loginLookup") String sLoginLookup) throws Exception
	{
		return userDao.countByLoginLookup(sLoginLookup);
	}

	@RequestMapping(userListDataURL)
	protected @ResponseBody Comparable[][] listUsersByLoginLookup(@RequestParam("loginLookup") String sLoginLookup, @RequestParam("page") int page, @RequestParam("size") int size) throws Exception
	{
		List<UserDetails> users = userDao.listByLoginLookup(sLoginLookup, Math.max(0, page), size);
		Comparable[][] result = new Comparable[users.size()][2];
		for (int i=0; i<users.size(); i++)
		{
			UserDetails ud = users.get(i);
			String sAuthoritySummary;
			if (ud.getAuthorities().contains(new GrantedAuthorityImpl(IRoleDefinition.ROLE_ADMIN)))
				sAuthoritySummary = "(ADMINISTRATOR)";
			else
			{
				HashSet<String> modules = new HashSet<>(userDao.getWritableEntityTypesByModule(ud.getAuthorities()).keySet());
				modules.addAll(userDao.getManagedEntitiesByModuleAndType(ud.getAuthorities()).keySet());
				modules.addAll(userDao.getCustomRolesByModuleAndEntityType(ud.getAuthorities()).keySet());
				sAuthoritySummary = modules.stream().collect(Collectors.joining(", "));
			}
			result[i][0] = ud.getUsername();
			result[i][1] = sAuthoritySummary;
		}
		return result;
	}

	@RequestMapping(value = userDetailsURL, method = RequestMethod.GET)
	protected void setupForm(Model model, @RequestParam(value="user", required=false) String username)
	{
		model.addAttribute("rolesByLevel1Type", rolesByLevel1Type);

		UserDetails user = username != null ? userDao.loadUserByUsername(username) : new User(" ", "", true, true, true, true, new ArrayList<GrantedAuthority>());
		model.addAttribute(user);
		Collection<? extends GrantedAuthority> loggedUserAuthorities = SecurityContextHolder.getContext().getAuthentication().getAuthorities();
		boolean fIsLoggedUserAdmin = loggedUserAuthorities.contains(new GrantedAuthorityImpl(IRoleDefinition.ROLE_ADMIN));
		Map<String /*module*/, Map<String /*entity-type*/, Collection<Comparable> /*entity-IDs*/>> managedEntitiesByModuleAndType = userDao.getManagedEntitiesByModuleAndType(loggedUserAuthorities);
		
		Collection<String> publicModules = new ArrayList(moduleManager.getModules(true)), publicModulesWithoutOwnedProjects = new ArrayList();
		if (!fIsLoggedUserAdmin)
			for (String sModule : publicModules)	// only show modules containing entities managed by logged user
				if (managedEntitiesByModuleAndType.get(sModule) == null)
					publicModulesWithoutOwnedProjects.add(sModule);
		model.addAttribute("publicModules", CollectionUtils.disjunction(publicModules, publicModulesWithoutOwnedProjects));
		
		Collection<String> privateModules = new ArrayList(moduleManager.getModules(false)), privateModulesWithoutOwnedProjects = new ArrayList();
		if (!fIsLoggedUserAdmin)
			for (String sModule : privateModules)	// only show modules containing entities managed by logged user
				if (managedEntitiesByModuleAndType.get(sModule) == null)
					privateModulesWithoutOwnedProjects.add(sModule);
		model.addAttribute("privateModules", CollectionUtils.disjunction(privateModules, privateModulesWithoutOwnedProjects));
	}

	@RequestMapping(value = userDetailsURL, method = RequestMethod.POST)
	protected String processForm(Model model, HttpServletRequest request) throws SecurityException, IllegalArgumentException, NoSuchMethodException, IllegalAccessException, InvocationTargetException, IOException
	{
		String sUserName = request.getParameter("username"), sPassword = request.getParameter("password");
		boolean fGotUserName = sUserName != null && sUserName.length() > 0;
		boolean fGotPassword = sPassword != null && sPassword.length() > 0;
		boolean fCloning = "true".equals(request.getParameter("cloning"));

		ArrayList<String> errors = new ArrayList<>();

		UserDetails user = null;
		if (fGotUserName)
			try
			{	
				user = userDao.loadUserByUsername(sUserName);
			}
			catch (UsernameNotFoundException unfe)
			{	// it's a new user, so make sure we have a password
				if (!fGotPassword && !fCloning)
					errors.add("You must specify a password");
			}

		if (!fGotPassword && user != null)
			sPassword = user.getPassword();		// password remains the same

		HashSet<String> entitiesOnWhichPermissionsWereExplicitlyApplied = new HashSet<>();
		HashSet<String> grantedAuthorityLabels = new HashSet<>();	// ensures unicity 
		
		Collection<? extends GrantedAuthority> loggedUserAuthorities = SecurityContextHolder.getContext().getAuthentication().getAuthorities();
		if (user != null && user.getAuthorities().contains(new GrantedAuthorityImpl(IRoleDefinition.ROLE_ADMIN)))
			grantedAuthorityLabels.add(IRoleDefinition.ROLE_ADMIN);
		else
		{
			for (String sModule : moduleManager.getModules(null))
			{
				for (String sEntityType : rolesByLevel1Type.keySet())
				{
					LinkedHashMap<Comparable, String> moduleEntities = (LinkedHashMap<Comparable, String>) moduleManager.getEntitiesByModule(sEntityType, null).get(sModule);
					for (Comparable entityId : moduleEntities.keySet())
						for (String anEntityRole : rolesByLevel1Type.get(sEntityType))
						{
							String sRole = urlEncode(sModule + ROLE_STRING_SEPARATOR + sEntityType + ROLE_STRING_SEPARATOR + anEntityRole + ROLE_STRING_SEPARATOR + entityId);
							if (request.getParameter(urlEncode(sRole)) != null)
								grantedAuthorityLabels.add(sRole);
						}
					
					Enumeration<String> it = request.getParameterNames();
					while (it.hasMoreElements())
					{
						String param = it.nextElement();
						if (param.equals(urlEncode(sEntityType + "Permission_" + sModule)))
						{
							String val = request.getParameter(param);
							if (val.length() > 0)
							{
								String validAuthorityLabels = "";	// may exclude unexisting entities
								for (String sRole : urlDecode(val).split(","))
								{
									String[] splittedPermission = sRole.split(Pattern.quote(ROLE_STRING_SEPARATOR));
									if (moduleManager.doesEntityExistInModule(splittedPermission[0], splittedPermission[1], splittedPermission[3]))
									{
										entitiesOnWhichPermissionsWereExplicitlyApplied.add(sModule + ROLE_STRING_SEPARATOR + sEntityType + ROLE_STRING_SEPARATOR + splittedPermission[3]);
										validAuthorityLabels += (validAuthorityLabels.isEmpty() ? "" : ",") + sRole;
									}
									else
										LOG.debug("skipping " + sRole);
								}
								if (validAuthorityLabels.length() > 0)
									grantedAuthorityLabels.add(validAuthorityLabels);
							}
						}
						else
						{
							String sRole = sModule + ROLE_STRING_SEPARATOR + sEntityType + ROLE_STRING_SEPARATOR + IRoleDefinition.CREATOR_ROLE_SUFFIX;							
							if (param.equals(urlEncode(sRole)))
								grantedAuthorityLabels.add(sRole);	// added because specified from GUI
							else if (user != null)
							{
								Collection<String> writableEntityTypes = userDao.getWritableEntityTypesByModule(user.getAuthorities()).get(sModule);
								if ((!(loggedUserAuthorities.contains(new GrantedAuthorityImpl(IRoleDefinition.ROLE_ADMIN))) && writableEntityTypes != null && writableEntityTypes.contains(sEntityType)))
									grantedAuthorityLabels.add(sRole);	// added because already existed
							}
						}
					}
				}
			}
		}

		if (user == null && !fGotUserName)
			errors.add("Username must not be empty");

		if (user != null)
		{	// make sure we don't loose permissions that are not set via this interface (i.e. roles on entities managed by other users than the connected one)
//			Map<String, Map<String, Collection<Comparable>>> managedEntitiesByModuleAndType = userDao.getOwnedEntitiesByModuleAndType(user.getAuthorities());
//			for (String sModule : managedEntitiesByModuleAndType.keySet())
//			{
//				Map<String, Collection<Comparable>> managedEntitiesByType = managedEntitiesByModuleAndType.get(sModule);
//				for (String sEntityType : managedEntitiesByType.keySet())
//					for (Comparable entityID : managedEntitiesByType.get(sEntityType))
//						grantedAuthorityLabels.add(sModule + ROLE_STRING_SEPARATOR + sEntityType + ROLE_STRING_SEPARATOR + IRoleDefinition.ENTITY_MANAGER_ROLE + ROLE_STRING_SEPARATOR + entityID);
//			}
			
			Map<String, Map<String, Map<String, Collection<Comparable>>>> customRolesByModuleAndEntityType = userDao.getCustomRolesByModuleAndEntityType(user.getAuthorities());
			for (String sModule : customRolesByModuleAndEntityType.keySet())
			{
				Map<String, Map<String, Collection<Comparable>>> rolesByEntityType = customRolesByModuleAndEntityType.get(sModule);
				for (String sEntityType : rolesByEntityType.keySet())
				{
					Map<String, Collection<Comparable>> entityIDsByRoles = rolesByEntityType.get(sEntityType);
					for (String role : entityIDsByRoles.keySet())
						for (Comparable entityId : entityIDsByRoles.get(role))
							if (!(loggedUserAuthorities.contains(new GrantedAuthorityImpl(IRoleDefinition.ROLE_ADMIN))) && !(loggedUserAuthorities.contains(new GrantedAuthorityImpl(sModule + ROLE_STRING_SEPARATOR + sEntityType + ROLE_STRING_SEPARATOR + IRoleDefinition.ENTITY_MANAGER_ROLE + ROLE_STRING_SEPARATOR + entityId))) && !entitiesOnWhichPermissionsWereExplicitlyApplied.contains(sModule + ROLE_STRING_SEPARATOR + sEntityType + ROLE_STRING_SEPARATOR + entityId))
								grantedAuthorityLabels.add(sModule + ROLE_STRING_SEPARATOR + sEntityType + ROLE_STRING_SEPARATOR + role + ROLE_STRING_SEPARATOR + entityId);
				}
			}
		}
		
		if (grantedAuthorityLabels.isEmpty())
			grantedAuthorityLabels.add(IRoleDefinition.DUMMY_EMPTY_ROLE);

		if (errors.size() > 0 || (!fGotPassword && fCloning))
		{
			ArrayList<GrantedAuthority> grantedAuthorities = new ArrayList<>();
			for (final String sGA : grantedAuthorityLabels)
				grantedAuthorities.add(new GrantedAuthorityImpl(sGA));
			user = new User(fGotUserName ? sUserName : " ", "", true, true, true, true, grantedAuthorities);
			model.addAttribute("errors", errors);
			setupForm(model, null);
			model.addAttribute(user);
			return userDetailsURL.substring(0, userDetailsURL.lastIndexOf("."));
		}

		userDao.saveOrUpdateUser(sUserName, sPassword, grantedAuthorityLabels.toArray(new String[grantedAuthorityLabels.size()]), true);
		return "redirect:" + userListPageURL;
	}

	@RequestMapping(value = userPermissionURL, method = RequestMethod.GET)
	protected void setupPermissionForm(Model model, @RequestParam("user") String username, @RequestParam("module") String module, @RequestParam("entityType") String entityType)
	{
		model.addAttribute(module);
		model.addAttribute("roles", rolesByLevel1Type.get(entityType));
		UserDetails user = null;	// we need to support the case where the user does not exist yet
		try
		{
			user = userDao.loadUserByUsername(username);
		}
		catch (UsernameNotFoundException ignored)
		{}
		model.addAttribute("user", user);
		boolean fVisibilitySupported = moduleManager.doesEntityTypeSupportVisibility(module, entityType);
		model.addAttribute("publicEntities", moduleManager.getEntitiesByModule(entityType, fVisibilitySupported ? true : null).get(module));
		if (fVisibilitySupported)
			model.addAttribute("privateEntities", moduleManager.getEntitiesByModule(entityType, false).get(module));
	}

	@RequestMapping(userRemovalURL)
	protected @ResponseBody boolean removeUser(@RequestParam("user") String sUserName) throws Exception
	{
		UserDetails user = userDao.loadUserByUsername(sUserName);
		if (user != null && user.getAuthorities().contains(new GrantedAuthorityImpl(IRoleDefinition.ROLE_ADMIN)))
			throw new Exception("Admin user cannot be deleted!");

		return userDao.deleteUser(sUserName);
	}

	// just a wrapper, for convenient use in JSPs
	public String urlEncode(String s) throws UnsupportedEncodingException
	{
		return URLEncoder.encode(s, "UTF-8");
	}
	
	// just a wrapper, for convenient use in JSPs
	public String urlDecode(String s) throws UnsupportedEncodingException
	{
		return URLDecoder.decode(s, "UTF-8");
	}
}
