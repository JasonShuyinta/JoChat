package lib;
import java.io.IOException;
import jolie.runtime.JavaService;
import jolie.runtime.Value;
import java.io.*;
import java.util.*;
import java.lang.String;
import jolie.runtime.*;
import java.util.Base64;
import java.security.*;
import java.lang.Exception;
import java.security.spec.X509EncodedKeySpec;
import java.security.spec.PKCS8EncodedKeySpec;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import java.security.spec.InvalidKeySpecException;
import javax.crypto.BadPaddingException;
import javax.crypto.NoSuchPaddingException;


public class Privata extends JavaService
{

  public static KeyPair generateRSAKkeyPair() throws Exception
	{
		SecureRandom secureRandom = new SecureRandom();

		KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");

		keyPairGenerator.initialize( 2048, secureRandom);

		return keyPairGenerator.generateKeyPair();

    }

    public static Value generatoreChiavi() {
      Value v= Value.create();

			try{
			KeyPair k= generateRSAKkeyPair();
			byte[] encodedBytesPub = k.getPublic().getEncoded();
			byte[] encodedBytesPriv = k.getPrivate().getEncoded();
			String chiavePubblica = Base64.getEncoder().encodeToString(encodedBytesPub);
			String chiavePrivata = Base64.getEncoder().encodeToString(encodedBytesPriv);
      v.getFirstChild("chiavePubblica").setValue(chiavePubblica);
      v.getFirstChild("chiavePrivata").setValue(chiavePrivata);

		}catch(Exception e){
			System.out.println(e);
		}
		return v;
    }




    // Encrypt message
    public Value encrypt(Value request)
    {
      Value v= Value.create();
      String chiavePubblica = request.getFirstChild("chiavePub").strValue();
      String message = request.getFirstChild("msg").strValue();
      try{
      byte[] chiaveByte= Base64.getDecoder().decode(chiavePubblica.getBytes());
      KeyFactory kf = KeyFactory.getInstance("RSA");
      PublicKey publicKey = kf.generatePublic(new X509EncodedKeySpec(chiaveByte));
      Cipher encryptCipher = Cipher.getInstance("RSA");
      encryptCipher.init(Cipher.ENCRYPT_MODE, publicKey);
      byte[] cipherText = encryptCipher.doFinal(message.getBytes());
      v.getFirstChild("messaggio").setValue(Base64.getEncoder().encodeToString(cipherText));
    }catch(Exception e){
      System.out.println(e);
    }
      return v;
    }

    //Decrypt message
    public Value decrypt(Value request)
    {
      Value v= Value.create();
      String chiavePrivata = request.getFirstChild("chiavePriv").strValue();
      String message = request.getFirstChild("messaggioCifrato").strValue();
      byte[] bytes=null;
      Cipher decriptCipher = null;
     try{
      byte[] chiaveByte= Base64.getDecoder().decode(chiavePrivata.getBytes());
      KeyFactory kf = KeyFactory.getInstance("RSA");
      PrivateKey privateKey = kf.generatePrivate(new PKCS8EncodedKeySpec(chiaveByte));
      bytes = Base64.getDecoder().decode(message);
      decriptCipher = Cipher.getInstance("RSA");
      decriptCipher.init(Cipher.DECRYPT_MODE, privateKey);
      v.getFirstChild("messaggioDecifrato").setValue(new String(decriptCipher.doFinal(bytes)));
   }catch(Exception e){
      System.out.println(e);
    }
      return v;
    }

    public Value creaFirma(Value request){
      Value v= Value.create();
      String chiavePrivata = request.getFirstChild("privKey").strValue();
      String message = request.getFirstChild("messaggio").strValue();
      String firmaDig = null;
      try{
      byte[] chiaveByte= Base64.getDecoder().decode(chiavePrivata.getBytes());
      KeyFactory kf = KeyFactory.getInstance("RSA");
      PrivateKey privateKey = kf.generatePrivate(new PKCS8EncodedKeySpec(chiaveByte));
      Signature sign = Signature.getInstance("SHA256withRSA");
      sign.initSign(privateKey);
      byte[] bytes = message.getBytes();
      sign.update(bytes);
      byte[] signature = sign.sign();
      firmaDig = Base64.getEncoder().encodeToString(signature);
      v.getFirstChild("firmaDigitale").setValue(firmaDig);
    }catch(Exception e){
       System.out.println(e);
     }
      return v;
    }

    public Value controlloFirma(Value request){
      Value v= Value.create();
      String result=null;
      String firma = request.getFirstChild("firma").strValue();
      String chiavePubblica = request.getFirstChild("keyPub").strValue();
      String mex = request.getFirstChild("messaggio").strValue();
      try{
      byte[] chiaveByte= Base64.getDecoder().decode(chiavePubblica.getBytes());
      KeyFactory kf = KeyFactory.getInstance("RSA");
      PublicKey publicKey = kf.generatePublic(new X509EncodedKeySpec(chiaveByte));
      byte[] firmaByte= Base64.getDecoder().decode(firma);
      Signature sign = Signature.getInstance("SHA256withRSA");
      sign.initVerify(publicKey);
      sign.update(mex.getBytes());
        //Verifying the signature
      boolean bool = sign.verify(firmaByte);
        if(bool)
          result="verificato";
        else
          result="fallito";
      v.getFirstChild("risultato").setValue(result);
    }catch(Exception e){
         System.out.println(e);
       }
       return v;
  }
}
