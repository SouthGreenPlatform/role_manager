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
jQuery.cookie=function(a,b,c){if("undefined"==typeof b){var i=null;if(document.cookie&&""!=document.cookie)for(var j=document.cookie.split(";"),k=0;k<j.length;k++){var l=jQuery.trim(j[k]);if(l.substring(0,a.length+1)==a+"="){i=decodeURIComponent(l.substring(a.length+1));break}}return i}c=c||{},null===b&&(b="",c.expires=-1);var d="";if(c.expires&&("number"==typeof c.expires||c.expires.toUTCString)){var e;"number"==typeof c.expires?(e=new Date,e.setTime(e.getTime()+24*c.expires*60*60*1e3)):e=c.expires,d="; expires="+e.toUTCString()}var f=c.path?"; path="+c.path:"",g=c.domain?"; domain="+c.domain:"",h=c.secure?"; secure":"";document.cookie=[a,"=",encodeURIComponent(b),d,f,g,h].join("")};