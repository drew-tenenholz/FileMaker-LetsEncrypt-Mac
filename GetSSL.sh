#!/bin/sh

# Created by: David Nahodyl, Blue Feather
# Contact: contact@bluefeathergroup.com
# Date: 2/1/2019
# Version: 0.3

# Need help? We can set this up to run on your server for you! Send an email to 
# contact@bluefeathergroup.com or give a call at (770) 765-6258

# This script is set up to INSTALL or RENEW the SSL certificate for FMServer

# Updated by Drew Tenenholz in March 2019 to lay out we may use the 'renew' option
# and only restart when a new certificate is actually available.
#
# Also includes some further explanation of various options.


# Change the domain variable to the domain/subdomain for which you would like
# an SSL Certificate
DOMAIN="fms.mycompany.com"

# Change the contact email address to your real email address so that Let's Encrypt
# can contact you if there are any problems #>
EMAIL="myemail@mycompoany.com"

# Enter the path to your FileMaker Server directory, ending in a slash 
SERVER_PATH="/Library/FileMaker Server/"

# Set the authentication type for Let's Encrypt.
# i.e. How will Let's Encrypt 'know' you own this server?
AUTH_CHALLENGE= "http"
# Prerequisites for http challenge:
#     A DNS entry for the DOMAIN
#     An open port 80 connection to the DOMAIN

# AUTH_CHALLENGE= "dns"
# Prerequisites for dns challenge:
#     A DNS entry for the DOMAIN
#     The ability to create/update the DNS entry for the DOMAIN to include
#     a TXT record with the preliminary results of the certificate request.
#     The DNS entry needs to be changed with EACH certificate renewal.

#
# --- you shouldn't need to edit anything below this line
#
# This is the path to the FMServer-installed web folder. You should be
# able to go to ${DOMAIN}:80 and see the "FileMaker Database Server
# Website" default web page from any machine in the world.  Let's
# Encrypt will contact this server when it issues/renews certificates.
WEB_ROOT="${SERVER_PATH}HTTPServer/htdocs"


# Issue the initial certificate
#    using certonly to simply collect the certificate and NOT install it anywhere
#    using webroot since there is already a web server running
#    using --agree-tos to accept the terms of service automatically
#    see preferred-challenges notes above
certbot certonly --webroot -w "$WEB_ROOT" -d $DOMAIN --agree-tos -m "$EMAIL" --preferred-challenges "$AUTH_CHALLENGE" -n

# Renew the certificate

#    This command should renew (all) certificates issued based on the configuration used to issue the certificate.
#    It will only run the post-hook if certbot actually tried to get a new certificate based on how soon it expires.
#    If you set up a FileMaker Server schedule to send you an email, this is one way to be notified that it is time
#    to install the renewed certificate
# certbot renew --preferred-challenges "$AUTH_CHALLENGE" -n --post-hook "fmsadmin run schedule 3"

#  move the files issued by Let's Encrypt to the FMServer CStore directory (they don't have the correct names yet).
cp "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" "${SERVER_PATH}CStore/fullchain.pem"
cp "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" "${SERVER_PATH}CStore/privkey.pem"

# set the permissions correctly
chmod 640 "${SERVER_PATH}CStore/privkey.pem"

# Move an old certificate, if there is one, to prevent an error
mv "${SERVER_PATH}CStore/serverKey.pem" "${SERVER_PATH}CStore/serverKey-old.pem"

# Install the certificate using the FileMaker Server CLI
fmsadmin certificate import "${SERVER_PATH}CStore/fullchain.pem" --keyfile "${SERVER_PATH}CStore/privkey.pem" -y

# In order for the new certificate to take effect, one MUST stop/restart FileMaker server.  This does is as part of the script.

# Stop FileMaker Server
launchctl stop com.filemaker.fms

# Wait 15 seconds for it to stop
sleep 15s

# Start FileMaker Server again
launchctl start com.filemaker.fms
