#!/softwares/python/bin/python

# Wed 12 Dec 04:13:50 CET 2016, LDIZ
# Tool for creating BigIP pools and monitors based on Swissquote standard
# 
import os, requests, json, time, getpass, datetime, sys

# Create:
# Pools monitors check
#
# Ex. trade_iwwltrade_apache-trade1_resin-trade1_sqb-am


# Define functions
def checkspecialcharsOK(s):
   if s.translate(None, "-_").isalnum(): return True
   else: 
      print "Remove special characters from your input."
      print
   

def convertunderscores(s):
   return s.replace("_", "-")


def getsite():
   os.system("clear")
   while True:
      s = raw_input("Enter site name (trade for trade.swissquote.ch)     : ")
      if checkspecialcharsOK(s): return s
      

def getapache():
   os.system("clear")
   while True:
      s = raw_input("Enter apache service name (trade1 for apache-trade1): ")
      if checkspecialcharsOK(s): return s


def getmemberbasename():
   os.system("clear")
   while True:
      s = raw_input("Enter pool member base name (iwtrade for iwtrade1gl/saz): ")
      if s.isalpha(): return s


def getappserver():
   os.system("clear")
   # Sanitize input from user
   while True:
      print "Application server types: "
      print "for Resin, type r"
      print "for Tomcat, type t"
      a = raw_input("Choose your application server type: ")
      if a == "r" or a == "t":
         while True:
            app = raw_input("Enter %s name (trade1 for %s-trade1)  : " % (appservertypes[a], 
                                                                          appservertypes[a].lower()))
            if checkspecialcharsOK(app): return a, app
      else:
         print "Wrong type."
         print
         continue

def getwebapp():
   os.system("clear")
   # Sanitize input from user
   return raw_input("Enter webapp name (sqb_am for /sqb_am)              : ")

def getmonitor():
   os.system("clear")
   # Sanitize input from user
   # Get monitor types
   while True:
      print "Monitor types:"
      print "for HTTP, type h"
      print "for HTTPS, type s"
      print "for TCP, type t"
      m = raw_input("Choose your monitor type: ")
      if m == "h" or m == "s" or m == "t":
         print 
         break
      else:
         print "Wrong type."
         continue
   # Get health check type
   if m == "t":
      return m, "t"
   while True:
      print "Health check types:"
      print "for ping.jsp, type p"
      print "for health/ping, type e"
      h = raw_input("Choose your health check type: ")
      if h == "p" or h == "e":
         return m, h
      else:
         print "Wrong type."
         continue

def getpoolmembers():
   os.system("clear")
   pm = []
   print "Add pool members (eg. iwwltrade1glz)."
   print "Type x when finished."
   while True:
      m = raw_input("Enter hostname: ")
      if m == "x": 
         return pm
      else: 
         pm.append(m)


def getportnumber():
   os.system("clear")
   # Sanitize input from user
   return raw_input("Enter port number (eg. 80 or 443)     : ")


def getcredentials():
   os.system("clear")
   bigips = {"1": ("PREPROD PF TRADING", "pfpre-ibigip1glx.bank.swissquote.ch"),
	     "2": ("PREPROD TRADING",    "pre-ibigip1glx.bank.swissquote.ch"),
	     "3": ("BANK",    "bbigip1glx.bank.swissquote.ch"),
             "4": ("STAGING TRADING",    "ibigipstg1gl.bank.swissquote.ch"),
             "5": ("STAGING 2 TRADING",    "ibigipstg2glx.info.swissquote.ch"),
             "6": ("UAT TRADING",        "uat-ibigip1glx.info.swissquote.ch"),
             "7": ("PROD    TRADING",    "ibigip2gl.info.swissquote.ch"),
            }
   for k in sorted(bigips.iterkeys()):
      print "%s: %s: %s" % (k, bigips[k][0], bigips[k][1])

   while True:
      selectedhostkey = raw_input("Select BigIP hostname number: ")
      if selectedhostkey in bigips: break
      else: print "Wrong number."
   u = raw_input("Enter your username: ")
   p = getpass.getpass("Enter your password: ")
   return {"host":bigips[selectedhostkey][1], "user":u, "pass":p}


def createmonitor(bigsession, host, monitorname, monitortype, healthchecktype, webapp):
   payload = {}
   payload["kind"] = "tm:ltm:monitor:%s:%sstate" % (monitortypes[monitortype].lower(), 
                                                    monitortypes[monitortype].lower())
   # BigIP Bank uses partitions
   if "bbigip1glx" in host:
      payload["partition"] = "Bank"
   
   # Other payload
   payload["name"] = monitorname
   payload["description"] = ""
   if healthchecktype == "p":
      payload["send"] = "GET /%s/ping.jsp\\r\\n" % webapp
      payload["recv"] = "<div>ping</div>"
   elif healthchecktype == "e":
      payload["send"] = "GET /%s/health/ping\\r\\n" % webapp
      payload["recv"] = "(OK|WARNING)"
   else: 
      return
   print healthchecktype

   bigsession.post("https://%s/mgmt/tm/ltm/monitor/%s" % (host, monitortypes[monitortype].lower()), data=json.dumps(payload))
   return


def createpool(bigsession, host, name, pms, monitorname, port):
   payload = {}

   # Convert member format
   #for m in pms: pms[pms.index(m)] = m + ":" + port
   formattedmembers = [ { 'kind' : 'ltm:pool:members', 'name' : m + ":" + port } for m in pms ]

   # Define test pool
   payload["kind"] = "tm:ltm:pool:poolstate"
   payload["name"] = name
   payload["description"] = ""
   payload["loadBalancingMode"] = "round-robin"
   payload["monitor"] = monitorname
   payload["members"] = formattedmembers

   # BigIP Bank uses partitions
   if "bbigip1glx" in host:
      payload["partition"] = "Bank"

   bigsession.post("https://%s/mgmt/tm/ltm/pool" % host, data=json.dumps(payload))
   return


def writetobigip(credentials, 
                 poolname, 
                 poolmembers, 
                 port,
                 monitorname,
                 monitortype,
                 healthchecktype,
                 webapp):
   os.system("clear")
   bigsession = requests.session() 
   bigsession.auth = (credentials["user"], credentials["pass"])
   bigsession.verify = False 
   bigsession.headers.update({'Content-Type' : 'application/json'})


   # Add port to pool member name, then create pool
   createmonitor(bigsession, credentials["host"], monitorname, monitortype, healthchecktype, webapp)
   createpool(bigsession, credentials["host"], poolname, poolmembers, monitorname, port)

   # Log attempted actions
   logfile = open("/logs/bigip/create-pool-bigip.log", "a")
   logfile.write("%s: on %s@%s attempted to create pool    %s\n" % (str(datetime.datetime.now()),
                                                                    credentials["user"],
                                                                    credentials["host"],
                                                                    poolname))
   logfile.write("%s: on %s@%s attempted to create monitor %s\n" % (str(datetime.datetime.now()),
                                                                    credentials["user"],
                                                                    credentials["host"],
                                                                    monitorname))
   logfile.close()
   print "On %s@%s attempted to create pool    %s" % (credentials["user"], credentials["host"], poolname)
   print "On %s@%s attempted to create monitor %s" % (credentials["user"], credentials["host"], monitorname)
   time.sleep(3)
 

def writetooutfile(filename):
   os.system("clear")
   outfile = open(filename, "a")
   outfile.write("%s, %s, %s, %s, %s, %s, %s, %s, %s \n"  %  (site,
                                                         apache,
                                                         appservertype, appserver,
                                                         webapp,
                                                         monitortype, healthchecktype,
                                                         poolmembers,
                                                         portnumber))
   outfile.close()
   print "Wrote file to %s" % filename
   time.sleep(3)
 

# Set default config
action = ""

# Get initial config
appservertypes     = {"r": "Resin", "t": "Tomcat"}
monitortypes       = {"h": "HTTP", "s": "HTTPS", "t": "TCP"}
healthchecktypes   = {"p": "ping.jsp", "e": "health/ping", "t": "tcp port check"}
outfilename        = "/var/tmp/create-pool-bigip.data"
site               = getsite()
memberbasename     = getmemberbasename()
apache             = getapache()
appservertype, appserver = getappserver()
#webapp,webappurl   = getwebapp()
webapp             = getwebapp()
monitortype, healthchecktype    = getmonitor()
poolmembers        = getpoolmembers()
portnumber         = getportnumber()
credentials        = {"host":"", "user":"", "pass":""}


# Run script only on sitx
if os.uname()[1] != "sitx":
   sys.exit("This script is supposed to be run on sitx only. Incident has been reported.")
   

# Run loop, ask to edit, 
while True:
   os.system("clear")
   print "CURRENT CONFIG:"
   print "(1) Site name          : %s" % site 
   print "(2) Server base name   : %s" % memberbasename 
   print "(3) Apache service name: %s" % apache 
   print "(4) %s service name    : %s" % (appservertypes[appservertype], appserver)
   print "(5) Webapp name        : %s" % webapp 
   print "(6) Monitor type       : %s" % monitortypes[monitortype]
   print "(6) Health check type  : %s" % healthchecktypes[healthchecktype]
   print "(7) Pool members       : %s" % " ".join(poolmembers)
   print "(8) Pool member port   : %s" % portnumber
   print
   print "Write data to"
   print "Host               : %s" % credentials["host"]
   print "Username           : %s" % credentials["user"]
   print
   print
   print "MENU"
   print "[ 1 ] to Change Site name"
   print "[ 2 ] to Change Base server name"
   print "[ 3 ] to Change Apache name"
   print "[ 4 ] to Change Application server service name (Resin or Tomcat)"
   print "[ 5 ] to Change Webapp name"
   print "[ 6 ] to Change Health monitor type"
   print "[ 7 ] to Change Pool members"
   print "[ 8 ] to Change Pool members port"
   print "[ l ] to Change BigIP credentials"
   print "[ w ] to Write above config to BigIP loadbalancer"
   print "[ f ] to Write above config to FILE"
   print "[ l ] to Load mass config from FILE, then Write config to BIGIP"
   print "[ x ] to Exit"
   action = raw_input("Ask action to do: ")
   if action == "f":
      # Write config to file
      writetooutfile(outfilename)
      continue
   if action == "w":
      if credentials["user"] == "": credentials = getcredentials()
      poolname = "%s_%s_apache-%s_%s-%s_%s" % (site, 
                                            memberbasename,
                                            apache, 
                                            appservertypes[appservertype].lower(), 
                                            convertunderscores(appserver), 
                                            convertunderscores(webapp))
      monitorname = "%s_apache-%s_%s-%s_%s" % (memberbasename,
                                            apache, 
                                            appservertypes[appservertype].lower(), 
                                            convertunderscores(appserver), 
                                            convertunderscores(webapp))
      writetobigip(credentials, poolname, poolmembers, portnumber, monitorname, monitortype, healthchecktype, webapp)
      continue
   if action == "l":
      credentials = getcredentials()
   if action == "8":
      portnumber = getportnumber() 
      continue
   if action == "7":
      poolmembers = getpoolmembers() 
      continue
   if action == "6":
      monitortype, healthchecktype = getmonitor() 
      continue
   if action == "5":
      webapp = getwebapp() 
      continue
   if action == "4":
      appservertype, appserver= getappserver() 
      continue
   if action == "3":
      apache = getapache() 
      continue
   if action == "2":
      memberbasename = getmemberbasename()
      continue
   if action == "1":
      site = getsite() 
      continue
   if action == "x":
      break
   else:
      continue


