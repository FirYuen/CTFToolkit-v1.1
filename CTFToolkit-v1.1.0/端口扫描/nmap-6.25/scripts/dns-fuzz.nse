local bit = require "bit"
local comm = require "comm"
local dns = require "dns"
local math = require "math"
local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"

description = [[
Launches a DNS fuzzing attack against DNS servers. 

The script induces errors into randomly generated but valid DNS packets.
The packet template that we use includes one uncompressed and one
compressed name.

Use the <code>dns-fuzz.timelimit</code> argument to control how long the
fuzzing lasts. This script should be run for a long time. It will send a
very large quantity of packets and thus it's pretty invasive, so it
should only be used against private DNS servers as part of a software
development lifecycle.
]]

---
-- @usage
-- nmap --script dns-fuzz --script-args timelimit=2h <target>
--
-- @args dns-fuzz.timelimit How long to run the fuzz attack. This is a
-- number followed by a suffix: <code>s</code> for seconds,
-- <code>m</code> for minutes, and <code>h</code> for hours. Use
-- <code>0</code> for an unlimited amount of time. Default:
-- <code>10m</code>.
--
-- @output
-- Host script results:
-- |_dns-fuzz: Server stopped responding... He's dead, Jim.

author = "Michael Pattrick"
license = "Same as Nmap--See http://nmap.org/book/man-legal.html"
categories = {"fuzzer", "intrusive"}


portrule = shortport.portnumber(53, "udp")

-- How many ms should we wait for the server to respond.
-- Might want to make this an argument, but 500 should always be more then enough.
DNStimeout = 500

-- Will the DNS server only respond to recursive questions
recursiveOnly = false

-- We only perform a DNS lookup of this site
recursiveServer = "scanme.nmap.org"

---
-- Checks if the server is alive/DNS
-- @param host  The host which the server should be running on
-- @param port  The servers port
-- @return      Bool, true if and only if the server is alive
function pingServer (host, port, attempts)
     local status, response, result
     -- If the server doesn't respond to the first in a multiattempt probe, slow down
     local slowDown = 1
     if not recursiveOnly then
          -- try to get a server status message
          -- The method that nmap uses by default
          local data
          local pkt = dns.newPacket()
          pkt.id = math.random(65535)
          
          pkt.flags.OC3 = true
          
          data = dns.encode(pkt)
          
          for i = 1, attempts do 
             status, result = comm.exchange(host, port, data, {proto="udp", timeout=math.pow(DNStimeout,slowDown)})
             if status then
               return true
             end
             slowDown = slowDown + 0.25
          end
          
          return false
     else
          -- just do a vanilla recursive lookup of scanme.nmap.org
          for i = 1, attempts do
               status, response = dns.query(recursiveServer, {host=host.ip, port=port.number, tries=1, timeout=math.pow(DNStimeout,slowDown)})
               if status then
                    return true
               end
               slowDown = slowDown + 0.25
          end
          return false
     end
end

---
-- Generate a random 'label', a string of ascii characters do be used in
-- the requested domain names
-- @return      Random string of lowercase characters
function makeWord ()
     local len =  math.random(3,7)
     local name = string.char(len)
     for i = 1, len do
          -- this next line assumes ascii
          name = name .. string.char(math.random(string.byte("a"),string.byte("z")))
     end
     return name
end

---
-- Turns random labels from makeWord into a valid domain name.
-- Includes the option to compress any given name by including a pointer
-- to the first record. Obviously the first record should not be compressed.
-- @param compressed  Bool, whether or not this record should have a compressed field
-- @return            A dns host string
function makeHost (compressed)
     -- randomly choose between 2 to 4 levels in this domain
     local levels = math.random(2,4)
     local name = ""
     for i = 1, levels do
          name = name .. makeWord ()
     end
     if compressed then
          name = name .. string.char(0xC0) .. string.char(0x0C)
     else
          name = name .. string.char(0x00)
     end

     return name
end

---
-- Concatenate all the bytes of a valid dns packet, including names generated by
-- makeHost(). This packet is to be corrupted.
-- @return      Always returns a valid packet
function makePacket()
     local recurs = 0x00
     if recursiveOnly then
          recurs = 0x01
     end
     return
         string.char( math.random(0,255), math.random(0,255),   -- TXID
                       recurs, 0x00,                             -- Flags, recursion disabled by default for obvious reasons
                       0x00, 0x02,                               -- Questions
                       0x00, 0x00,                               -- Answer RRs
                       0x00, 0x00,                               -- Authority RRs
                       0x00, 0x00)                               -- Additional RRs
                       -- normal host
                       .. makeHost (false) ..                    -- Hostname
          string.char( 0x00, 0x01,                               -- Type (A)
                       0x00, 0x01)                               -- Class (IN)
                       -- compressed host
                       .. makeHost (true) ..                     -- Hostname
          string.char( 0x00, 0x05,                               -- Type (CNAME)
                       0x00, 0x01)                               -- Class (IN)
end

---
-- Introduce bit errors into a packet at a rate of 1/50
-- As Charlie Miller points out in "Fuzz by Number"
-- -> cansecwest.com/csw08/csw08-miller.pdf 
-- It's difficult to tell how much random you should insert into packets
-- "If data is too valid, might not cause problems, If data is too invalid,
--  might be quickly rejected"
-- so 1/50 is arbitrary
-- @param dnsPacket  A packet, generated by makePacket()
-- @return           The same packet, but with bit flip errors
function nudgePacket (dnsPacket)
     local newPacket = ""
     -- Iterate over every byte in the packet
     dnsPacket:gsub(".", function(c)
          -- Induce bit errors at a rate of 1/50.
          if math.random(50) == 25 then
               -- Bitflip algorithm: c ^ 1<<(rand()%7)
               newPacket = newPacket .. string.char( bit.bxor(c:byte(), bit.lshift(1, math.random(0,7))) )
          else
               newPacket = newPacket .. c
          end
     end)
     return newPacket
end

---
-- Instead of flipping a bit, we drop an entire byte
-- @param dnsPacket  A packet, generated by makePacket()
-- @return           The same packet, but with a single byte missing
function dropByte (dnsPacket)
     local newPacket = ""
     local byteToDrop = math.random(dnsPacket:len())-1
     local i = 0
     -- Iterate over every byte in the packet
     dnsPacket:gsub(".", function(c)
          i=i+1
          if not i==byteToDrop then
               newPacket = newPacket .. c
          end
     end)
     return newPacket
end

---
-- Instead of dropping an entire byte, in insert a random byte
-- @param dnsPacket  A packet, generated by makePacket()
-- @return           The same packet, but with a single byte missing
function injectByte (dnsPacket)
     local newPacket = ""
     local byteToInject = math.random(dnsPacket:len())-1
     local i = 0
     -- Iterate over every byte in the packet
     dnsPacket:gsub(".", function(c)
          i=i+1
          if i==byteToInject then
               newPacket = newPacket .. string.char(math.random(0,255)) 
          end
          newPacket = newPacket .. c
     end)
     return newPacket
end

---
-- Instead of dropping an entire byte, in insert a random byte
-- @param dnsPacket  A packet, generated by makePacket()
-- @return           The same packet, but with a single byte missing
function truncatePacket (dnsPacket)
     local newPacket = ""
     -- at least 12 bytes to make sure the packet isn't dropped as a tinygram
     local eatPacketPos = math.random(12,dnsPacket:len())-1
     local i = 0
     -- Iterate over every byte in the packet
     dnsPacket:gsub(".", function(c)
          i=i+1
          if i==eatPacketPos then
               return
          end
          newPacket = newPacket .. c
     end)
     return newPacket
end

---
-- As the name of this function suggests, we corrupt the packet, and then send it.
-- We choose at random one of three corruption functions, and then corrupt/send
-- the packet a maximum of 10 times
-- @param host      The servers IP
-- @param port      The servers port
-- @param query     An uncorrupted DNS packet
-- @return          A string if the server died, else nil
function corruptAndSend (host, port, query)
     local randCorr = math.random(0,4)
     local status
     local result
     -- 10 is arbitrary, but seemed like a good number
     for j = 1, 10 do
          if randCorr<=1  then
               -- slight bias to nudging because it seems to work better
               query = nudgePacket(query)
          elseif randCorr==2  then
               query = dropByte(query)
          elseif randCorr==3  then
               query = injectByte(query)
          elseif randCorr==4  then
               query = truncatePacket(query)
          end
          
          status, result = comm.exchange(host, port, query, {proto="udp", timeout=DNStimeout})
          if not status then
               if not pingServer(host,port,3) then
                    -- no response after three tries, the server is probably dead
                    return "Server stopped responding... He's dead, Jim.\n"..
                           "Offending packet: 0x".. stdnse.tohex(query)
               else
                    -- We corrupted the packet too much, the server will just drop it
                    -- No point in using it again
                    return nil
               end
          end
          if randCorr==4  then
               -- no point in using this function more then once
               return nil
          end
     end
     return nil
end

action = function(host, port)
     local endT
     local timelimit, err
     local retStr
     local query
     
     for _, k in ipairs({"dns-fuzz.timelimit", "timelimit"}) do
          if nmap.registry.args[k] then
               timelimit, err = stdnse.parse_timespec(nmap.registry.args[k])
               if not timelimit then
                    error(err)
               end
               break
          end
     end
     if timelimit and timelimit > 0 then
          -- seconds to milliseconds plus the current time
          endT = timelimit*1000 + nmap.clock_ms()
     elseif not timelimit then
          -- 10 minutes
          endT = 10*60*1000 + nmap.clock_ms()
     end
     
     
     -- Check if the server is a DNS server.
     if not pingServer(host,port,1) then
          -- David reported that his DNS server doesn't respond to
          recursiveOnly = true
          if not pingServer(host,port,1) then
               return "Server didn't response to our probe, can't fuzz"
          end
     end
     nmap.set_port_state (host, port, "open")

     -- If the user specified that we should run for n seconds, then don't run for too much longer
     -- If 0 seconds, then run forever
     while not endT or nmap.clock_ms()<endT do
          -- Forge an initial packet
          -- We start off with an only slightly corrupted packet, then add more and more corruption
          -- if we corrupt the packet too much then the server will just drop it, so we only recorrupt several times
          -- then start all over
          query =  makePacket ()
          -- induce random jitter
          retStr = corruptAndSend (host, port, query)
          if not retStr==nil then
               return retStr
          end
     end
     return "The server seems impervious to our assault."
end
