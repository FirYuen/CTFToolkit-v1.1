#
# This script was written by Renaud Deraison <deraison@cvs.nessus.org>
#
# See the Nessus Scripts License for details
#

if(description)
{
 script_id(10301);
 script_bugtraq_id(2077);
 script_version ("$Revision: 1.18 $");
 script_cve_id("CVE-1999-0196");
 
 name["english"] = "websendmail";
 name["francais"] = "websendmail";
 script_name(english:name["english"], francais:name["francais"]);
 
 desc["english"] = "The 'websendmail' CGI is installed. This CGI has
a well known security flaw that lets an attacker execute arbitrary
commands with the privileges of the http daemon (usually root or nobody).

Solution : Remove it from /cgi-bin.

Risk factor : High";


 desc["francais"] = "Le cgi 'websendmail' est install�. Celui-ci poss�de
un probl�me de s�curit� bien connu qui permet � n'importe qui de faire
executer des commandes arbitraires au daemon http, avec les privil�ges
de celui-ci (root ou nobody). 

Solution : retirez-le de /cgi-bin.

Facteur de risque : S�rieux";


 script_description(english:desc["english"], francais:desc["francais"]);
 
 summary["english"] = "Checks for the presence of /cgi-bin/websendmail";
 summary["francais"] = "V�rifie la pr�sence de /cgi-bin/websendmail";
 
 script_summary(english:summary["english"], francais:summary["francais"]);
 
 script_category(ACT_GATHER_INFO);
 
 
 script_copyright(english:"This script is Copyright (C) 1999 Renaud Deraison",
		francais:"Ce script est Copyright (C) 1999 Renaud Deraison");
 family["english"] = "CGI abuses";
 family["francais"] = "Abus de CGI";
 script_family(english:family["english"], francais:family["francais"]);
 script_dependencie("find_service.nes", "no404.nasl");
 script_require_ports("Services/www", 80);
 exit(0);
}

#
# The script code starts here
#
include("http_func.inc");
include("http_keepalive.inc");
port = get_http_port(default:80);
res = is_cgi_installed_ka(item:"websendmail", port:port);
if(res)security_hole(port);

