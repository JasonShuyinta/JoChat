package lib;
import java.io.DataInputStream;
import java.io.IOException;
import java.math.BigInteger;
import java.util.Random;
import jolie.runtime.JavaService;
import jolie.runtime.Value;
import java.io.*;
import java.util.*;
import java.lang.String;
import jolie.runtime.*;


public class Privata extends JavaService
{
    private BigInteger p;
    private BigInteger q;
    private BigInteger N;
    private BigInteger phi;
    private BigInteger e;
    private BigInteger d;
    private int        bitlength = 1024;
    private Random     r;

/*
    public ChatPrivata(BigInteger e, BigInteger d, BigInteger N)
    {
        this.e = e;
        this.d = d;
        this.N = N;
    }
*/

    public String generatoreChiavi()
    {
      r = new Random();
      p = BigInteger.probablePrime(bitlength, r);
      q = BigInteger.probablePrime(bitlength, r);
      N = p.multiply(q);
      phi = p.subtract(BigInteger.ONE).multiply(q.subtract(BigInteger.ONE));
      e = BigInteger.probablePrime(bitlength / 2, r);
      while (phi.gcd(e).compareTo(BigInteger.ONE) > 0 && e.compareTo(phi) < 0)
      {
          e.add(BigInteger.ONE);
      }
      d = e.modInverse(phi);

      String stringaN = String.valueOf(N);
      String stringaD = String.valueOf(d);
      String stringaE = String.valueOf(e);
      String chiavePrivata = stringaN+"/"+stringaD;
      String chiavePubblica = stringaN+"/"+stringaE;
      String coppiaChiavi= chiavePrivata+"-"+chiavePubblica;
      return coppiaChiavi;
    }

    public static String splitKeysN(String chiave){
     String[] keysArray = chiave.split("/");
     String valoreN = keysArray[0];
     return valoreN;
   }
    public static String splitKeysNtoE(String chiavePubblica){
			String[] keysArray = chiavePubblica.split("/");
			String valoreE = keysArray[1];
			return valoreE;
		}

    public static String splitKeysNtoD(String chiavePrivata){
			String[] keysArray = chiavePrivata.split("/");
			String valoreD = keysArray[1];
			return valoreD;
		}

    public static String splitKeysPriv(String keys){
			String[] keysArray = keys.split("-");
			String temp = keysArray[0];
			return temp;
		}

		public static String splitKeysPub(String keys){
			String[] keysArray = keys.split("-");
			String temp1 = keysArray[1];
			return temp1;
		}

    // Encrypt message
    public Value encrypt(Value request)
    {
      Value v= Value.create();
      String stringE = request.getFirstChild("valoreE").strValue();
      String stringN = request.getFirstChild("valoreN").strValue();
      BigInteger e1 = new BigInteger(stringE);
      BigInteger N1 = new BigInteger(stringN);
      String messaggio = request.getFirstChild("msg").strValue();
      byte[] bytesMessaggio = messaggio.getBytes();
      byte[] tmp = (new BigInteger(bytesMessaggio)).modPow(e1, N1).toByteArray();
      ByteArray byteArray= new ByteArray(tmp);
      v.getFirstChild("risposta").setValue(byteArray);
      return v;
    }

    //Decrypt message
    public String decrypt(Value request)
    {
      String stringD = request.getFirstChild("valoreD").strValue();
      String stringN = request.getFirstChild("valoreN").strValue();
      BigInteger d1 = new BigInteger(stringD);
      BigInteger N1 = new BigInteger(stringN);
      byte[] messCifrato = request.getFirstChild("msg").byteArrayValue().getBytes();
      byte[] tmp1 = (new BigInteger(messCifrato)).modPow(d1, N1).toByteArray();
      String tmpConverted = new String(tmp1);
      return tmpConverted;
    }
  }
