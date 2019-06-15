#!/usr/bin/python
#
#
# Usage: sh wlst.sh jrf_domain.py <domain home> <rcu schema prefix> <db connect string if not localhost:1521/orcl> [<domain encryption key>, <domain encryption key password>]
#
#  <domain encryption key>, <domain encryption key password> are optional. They are set when creating a domain to join existing security store
#  the key can be exported from existing domain with WLST command like:
#exportEncryptionKey(jpsConfigFile='<domain_home>/config/fmwconfig/jps-config-jse.xml', keyFilePath='./domain_key', keyFilePassword='welcome1')
#
#
# NOTE: modify wls port, wls admin password, customer.key.password per whatever value you may want or modify this script to take the password as a#        cmd line paramater

import inspect
import os

scriptname = os.path.abspath(sys.argv[0])
scriptpath = os.path.dirname(scriptname)
dbURL_default = "jdbc:oracle:thin:@localhost:1521/orcl"

try:
    argLen = len(sys.argv)
    if argLen < 3:
        print "Usage: jrf_domain.py <domain_home> <schema_prefix> <db_url> [<domain encryption key>, <domain encryption key password>]"
        sys.exit()
    domain_home = sys.argv[1]
    schema_prefix = sys.argv[2]
    db_details = sys.argv[3]

    if argLen >= 5:
        keyPath = sys.argv[4]
        keyPw = sys.argv[5]

    port = '9001'
    password = 'welcome1'
    if domain_home is None:
        sys.exit("Error: Please set the property domain.home")
    if port is None:
        sys.exit("Error: Please set the property wls.adminport")
    if password is None:
        sys.exit("Error: Please set the property wls.password")
    if schema_prefix is None:
        sys.exit("Error: Please specify schema prefix")
    if db_details is None:
        dbURL = dbURL_default
    else:
        dbURL = "jdbc:oracle:thin:@" + db_details
except (KeyError), why:
    sys.exit("Error: Missing properties " + str(why))

wls_template = 'Basic WebLogic Server Domain'
jrf_template = 'Oracle JRF'

print "Creating domain in '" + domain_home + "' using base WLS template"
print "Connecting to '" + dbURL + "' using prefix '" + schema_prefix + "'"
try:
    setTopologyProfile('Expanded')
    selectTemplate(wls_template)
    loadTemplates()
    cd(r'/Security/base_domain/User/weblogic')
    cmo.setPassword(password)
    cd(r'/Server/AdminServer')
    cmo.setName('AdminServer')

    print "Setting listen port of admin server to: " + str(port);
    cmo.setListenPort(Integer.parseInt(port))
    writeDomain(domain_home)
    closeTemplate()

    print "Reading the new domain"
    readDomain(domain_home)
    print "Applying JRF template"
    selectTemplate(jrf_template)
    print "Loading JRF template"
    loadTemplates()
    showTemplates()

    print "Configuring data sources"
    cd('JDBCSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource')
    cd('JDBCDriverParams/NO_NAME_0')
    set('DriverName','oracle.jdbc.OracleDriver')
    set('URL', dbURL)
    #set('URL','jdbc:oracle:thin:@adc6170548.us.oracle.com:1521/orcl')
    set('PasswordEncrypted', 'welcome1')
    cd('Properties/NO_NAME_0')
    cd('Property/user')
    cmo.setValue(schema_prefix + '_STB')


    if argLen >= 5:
        setSharedSecretStoreWithPassword(keyPath, keyPw)

    print "Fetching data source configurations"
    getDatabaseDefaults()

    print "Updating domain"
    updateDomain();
    print "Domain updated."
    closeDomain()
    print "Domain closed."

    print "Reading the new domain"
    readDomain(domain_home)
    print "Reading the new domain done"

except:
    dumpStack()
exit()
