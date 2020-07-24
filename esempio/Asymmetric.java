// Java program to create a
// asymmetric key

package esempio;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.SecureRandom;
import java.util.Base64;
import java.io.*;
import java.util.*;
import jolie.runtime.JavaService;
//import jolie.runtime.embedding.RequestResponse;



// Class to create an asymmetric key
public class Asymmetric extends JavaService{


	private static final String RSA= "RSA";

	// Generating public and private keys
	// using RSA algorithm.
	public static KeyPair generateRSAKkeyPair() throws Exception
	{
		SecureRandom secureRandom = new SecureRandom();

		KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance(RSA);

		keyPairGenerator.initialize( 2048, secureRandom);

		return keyPairGenerator.generateKeyPair();

    }

    public static String generatoreChiavi() {
			String ritorno = null;

			try{
			KeyPair k= generateRSAKkeyPair();
			byte[] encodedBytesPub = k.getPublic().getEncoded();
			byte[] encodedBytesPriv = k.getPrivate().getEncoded();
			String chiavePubblica = Base64.getEncoder().encodeToString(encodedBytesPub);
			String chiavePrivata = Base64.getEncoder().encodeToString(encodedBytesPriv);

			ritorno = chiavePrivata + "." + chiavePubblica;

		}catch(Exception e){
			System.out.println(e);
		}
		return ritorno;
    }

}
