package fr.cirad.security;

import java.util.regex.Pattern;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class CustomBCryptPasswordEncoder extends BCryptPasswordEncoder {

    private Pattern BCRYPT_PATTERN = Pattern.compile("\\A\\$2a?\\$\\d\\d\\$[./0-9A-Za-z]{53}");
    
	public boolean looksLikeBCrypt(String encodedPassword)
	{
		return BCRYPT_PATTERN.matcher(encodedPassword).matches();
	}
}