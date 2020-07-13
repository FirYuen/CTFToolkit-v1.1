#
# (C) Tenable Network Security
#
if(description)
{
 script_id(15962);
 script_version("$Revision: 1.3 $");
 script_bugtraq_id(11763, 11922);
 script_cve_id("CAN-2004-0567", "CAN-2004-1080");
 name["english"] = "WINS Code Execution (870763) (registry check)";
 
 script_name(english:name["english"]);
 
 desc["english"] = "
The remote Windows Internet Naming Service (WINS) is vulnerable to a 
flaw which could allow an attacker to execute arbitrary code on this host.

To exploit this flaw, an attacker would need to send a specially crafted
packet on port 42 of the remote host.

Solution : http://www.microsoft.com/technet/security/bulletin/ms04-045.mspx
Risk factor : High";

 script_description(english:desc["english"]);
 
 summary["english"] = "Checks the remote registry for MS04-045";

 script_summary(english:summary["english"]);
 
 script_category(ACT_GATHER_INFO);
 
 script_copyright(english:"This script is Copyright (C) 2004 Tenable Network Security");
 family["english"] = "Windows : Microsoft Bulletins";
 script_family(english:family["english"]);
 
 script_dependencies("smb_hotfixes.nasl");
 script_require_keys("SMB/Registry/Enumerated");
 exit(0);
}

include("smb_hotfixes.inc");


if ( hotfix_check_nt_server() <= 0 ) exit(0);
if ( hotfix_check_wins_installed() <= 0 ) exit(0);
if ( hotfix_check_sp(nt:7, win2k:5, win2003:1) <= 0 ) exit(0);

if ( hotfix_missing(name:"870763") > 0 )
	security_hole(get_kb_item("SMB/transport"));
