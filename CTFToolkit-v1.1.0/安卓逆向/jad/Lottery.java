// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 

import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.*;
import java.util.Arrays;
import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import javax.servlet.RequestDispatcher;
import javax.servlet.http.*;

public class Lottery extends HttpServlet
{

    public Lottery()
    {
    }

    private static byte[] a()
    {
        return Arrays.copyOfRange(Files.readAllBytes(Paths.get(a, new String[0])), 0, 16);
    }

    private static byte[] b()
    {
        return Files.readAllBytes(Paths.get(b, new String[0]));
    }

    private static byte[] a(String s)
    {
        MessageDigest messagedigest;
        return s = (messagedigest = MessageDigest.getInstance("MD5")).digest(s.getBytes("UTF-8"));
    }

    private static void a(HttpServletResponse httpservletresponse, String s)
    {
        httpservletresponse = httpservletresponse.getWriter();
        s = (s = s.replace("\\", "\\\\")).replace("\"", "\\\"");
        httpservletresponse.println((new StringBuilder("{\"msg\": \"")).append(s).append("\"}").toString());
    }

    private boolean a(byte byte0, int i)
    {
        return byte0 == a()[i];
    }

    private static int b(String s)
    {
        return Integer.parseInt(s);
    }

    private static String a(byte abyte0[])
    {
        StringBuilder stringbuilder = new StringBuilder();
        for(int i = 0; i < abyte0.length; i++)
            stringbuilder.append(String.format("%02x", new Object[] {
                Byte.valueOf(abyte0[i])
            }));

        return stringbuilder.toString();
    }

    private static String a(int i)
    {
        i = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890".toCharArray();
        SecureRandom securerandom = new SecureRandom();
        StringBuilder stringbuilder = new StringBuilder();
        for(int j = 0; j < 16; j++)
        {
            int k = securerandom.nextInt(65535) % i.length;
            stringbuilder.append(i[k]);
        }

        return stringbuilder.toString();
    }

    public void doGet(HttpServletRequest httpservletrequest, HttpServletResponse httpservletresponse)
    {
        httpservletresponse.setContentType("text/html");
        httpservletresponse.setCharacterEncoding("UTF-8");
        Object obj = httpservletrequest.getSession();
        httpservletresponse.getWriter();
        ((HttpSession) (obj)).setAttribute("prefix", a(16));
        ((RequestDispatcher) (obj = httpservletrequest.getRequestDispatcher("WEB-INF/jsp/index.jsp"))).forward(httpservletrequest, httpservletresponse);
    }

    public void doPost(HttpServletRequest httpservletrequest, HttpServletResponse httpservletresponse)
    {
        httpservletresponse.setContentType("application/json");
        httpservletresponse.setCharacterEncoding("UTF-8");
        HttpSession httpsession = httpservletrequest.getSession();
        httpservletresponse.getWriter();
        Object obj;
        if((obj = httpsession.getAttribute("prefix")) == null)
            obj = a(16);
        else
            obj = (String)obj;
        httpsession.setAttribute("prefix", a(16));
        byte abyte0[] = {
            0
        };
        String s = httpservletrequest.getParameter("captcha");
        try
        {
            abyte0 = a((new StringBuilder()).append(((String) (obj))).append(s).toString());
        }
        catch(NoSuchAlgorithmException _ex) { }
        int i;
        String s1;
        if((i = Integer.parseInt(((String) (obj = httpservletrequest.getParameter("line"))))) >= 0 && i <= 3)
            s1 = "333";
        else if(i >= 4 && i <= 7)
            s1 = "4444";
        else if(i >= 8 && i <= 11)
            s1 = "55555";
        else if(i >= 12 && i <= 15){
            s1 = "666666";
        } else {
            a(httpservletresponse, "line error");
            return;
        }

        if((obj = httpservletrequest.getParameter("guess")) == null || ((String)obj).equals(""))
        {
            a(httpservletresponse, "guess not found");
            return;
        }

        byte byte1 = (byte)httpservletrequest.getParameter("guess").toCharArray()[0];
        
        if(a(abyte0).startsWith(s1))
        {
            int j = i; // i 为选择列表的索引号
            byte byte0 = byte1; // guess 参数的第一个字符
            Lottery lottery = this;
            if(byte0 == a()[j])
            {
                if(i == 15)
                {
                    byte abyte1[] = {
                        0
                    };
                    try
                    {
                        abyte1 = a((new StringBuilder()).append(httpservletrequest.getRemoteAddr()).append(new String(a())).toString());
                    }
                    catch(NoSuchAlgorithmException _ex) { }
                    try
                    {
                        httpservletrequest = new SecretKeySpec(abyte1, "AES");
                        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
                        IvParameterSpec ivparameterspec = new IvParameterSpec(c.getBytes("UTF-8"));
                        cipher.init(1, httpservletrequest, ivparameterspec);
                        httpservletrequest = cipher.doFinal(Files.readAllBytes(Paths.get(b, new String[0])));
                        a(httpservletresponse, (new StringBuilder("encrypted flag is ")).append(a(httpservletrequest)).toString());
                    }
                    catch(Exception _ex)
                    {
                        a(httpservletresponse, "encryption error");
                        return;
                    }
                } else
                {
                    a(httpservletresponse, "good");
                    return;
                }
            } else
            {
                a(httpservletresponse, "bad luck");
                return;
            }
        } else
        {
            a(httpservletresponse, "captcha error");
        }
    }

    public void destroy()
    {
    }

    private static String a = "/SECRET";
    private static String b = "/FLAG";
    private static String c = "0011223344556677";

}
