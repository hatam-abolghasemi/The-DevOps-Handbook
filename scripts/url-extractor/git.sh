#!/bin/bash

# PLACE THIS SCRIPT NEXT TO WHERE THERE ARE A LOT OF GIT PROJECTS.
num_cores=$(nproc)
function checkout_pull() {
  local dir="$1"
  if [[ -d "$dir/.git" ]]; then
    cd "$dir" || return
    tput el
    echo -ne "Updating project:$dir\r"
    git checkout develop &> /dev/null
    git pull &> /dev/null
    cd - &> /dev/null
  fi
}
for dir in */; do
  checkout_pull "$dir" &
  while [[ $(jobs -r | wc -l) -ge $num_cores ]]; do
    sleep 1
  done
done
wait
tput el
echo "Finished updating all projects!"

> extractor.log
> cleaner.log
> url.log
echo -ne "Looking for URLs\r"
find . -type f -exec grep -P "http[s]://([^>]+)" {} \; >> extractor.log 2>&1
grep -E 'http://|https://' extractor.log | while read -r line; do
    extracted_line=$(echo "$line" | sed -n 's/.*\(http[s]*:\/\/[^'\'']*\).*/\1/p')
    if [[ ! $extracted_line =~ }i ]] &&
		[[ ! $extracted_line =~ 64robots.com ]] &&
		[[ ! $extracted_line =~ adpdigital.com ]] &&
		[[ ! $extracted_line =~ aka.ms ]] &&
		[[ ! $extracted_line =~ alpk.in ]] &&
		[[ ! $extracted_line =~ amazonaws.com ]] &&
		[[ ! $extracted_line =~ anardoni.com ]] &&
		[[ ! $extracted_line =~ antennae ]] &&
		[[ ! $extracted_line =~ apa.org ]] &&
		[[ ! $extracted_line =~ apache.org ]] &&
		[[ ! $extracted_line =~ appannie.com ]] &&
		[[ ! $extracted_line =~ apple.co ]] &&
		[[ ! $extracted_line =~ appsto.re ]] &&
		[[ ! $extracted_line =~ appveyor.com ]] &&
		[[ ! $extracted_line =~ b2n.ir ]] &&
		[[ ! $extracted_line =~ bbci.co.uk ]] &&
		[[ ! $extracted_line =~ benramsey.com ]] &&
		[[ ! $extracted_line =~ betterstack.com ]] &&
		[[ ! $extracted_line =~ bigcartel.com ]] &&
		[[ ! $extracted_line =~ bit.ly ]] &&
		[[ ! $extracted_line =~ bitnami.com ]] &&
		[[ ! $extracted_line =~ bl.ocks.org ]] &&
		[[ ! $extracted_line =~ blindsignals.com ]] &&
		[[ ! $extracted_line =~ bootstrapcdn.com ]] &&
		[[ ! $extracted_line =~ bower.io ]] &&
		[[ ! $extracted_line =~ bunny.net ]] &&
		[[ ! $extracted_line =~ cafebazaar.ir ]] &&
		[[ ! $extracted_line =~ cakephp.org ]] &&
		[[ ! $extracted_line =~ cdn77.org ]] &&
		[[ ! $extracted_line =~ chabok.io ]] &&
		[[ ! $extracted_line =~ choosealicense.com ]] &&
		[[ ! $extracted_line =~ choosealicense.org ]] &&
		[[ ! $extracted_line =~ chromium.org ]] &&
		[[ ! $extracted_line =~ cl.cam.ac.uk ]] &&
		[[ ! $extracted_line =~ clearbit.com ]] &&
		[[ ! $extracted_line =~ cloud.google.com ]] &&
		[[ ! $extracted_line =~ cloudflare.com ]] &&
		[[ ! $extracted_line =~ codacy.com ]] &&
		[[ ! $extracted_line =~ code.google.com ]] &&
		[[ ! $extracted_line =~ codecov.io ]] &&
		[[ ! $extracted_line =~ contributor-covenant.org ]] &&
		[[ ! $extracted_line =~ coveralls.io ]] &&
		[[ ! $extracted_line =~ cp-algorithms.com ]] &&
		[[ ! $extracted_line =~ crisp.chat ]] &&
		[[ ! $extracted_line =~ csswg.org ]] &&
		[[ ! $extracted_line =~ cubettech.com ]] &&
		[[ ! $extracted_line =~ curl.se ]] &&
		[[ ! $extracted_line =~ curotec.com ]] &&
		[[ ! $extracted_line =~ cyber-duck.co.uk ]] &&
		[[ ! $extracted_line =~ daneden.me ]] &&
		[[ ! $extracted_line =~ davedevelopment.co.uk ]] &&
		[[ ! $extracted_line =~ danlew.net ]] &&
		[[ ! $extracted_line =~ deprecations-description ]] &&
		[[ ! $extracted_line =~ devsquad.com ]] &&
		[[ ! $extracted_line =~ discord.com ]] &&
		[[ ! $extracted_line =~ discord.gg ]] &&
		[[ ! $extracted_line =~ doc.gov ]] &&
		[[ ! $extracted_line =~ docker.com ]] &&
		[[ ! $extracted_line =~ doctrine-project.org ]] &&
		[[ ! $extracted_line =~ domain.tld ]] &&
		[[ ! $extracted_line =~ domenic.me ]] &&
		[[ ! $extracted_line =~ drupal.org ]] &&
		[[ ! $extracted_line =~ ecologi.com ]] &&
		[[ ! $extracted_line =~ elastic.co ]] &&
		[[ ! $extracted_line =~ estl.ir ]] &&
		[[ ! $extracted_line =~ example.com ]] &&
		[[ ! $extracted_line =~ facebook.com ]] &&
		[[ ! $extracted_line =~ fastify.io ]] &&
		[[ ! $extracted_line =~ feross.org ]] &&
		[[ ! $extracted_line =~ fileformat.info ]] &&
		[[ ! $extracted_line =~ fleep.io ]] &&
		[[ ! $extracted_line =~ fluidproject.org ]] &&
		[[ ! $extracted_line =~ fonts.googleapis.com ]] &&
		[[ ! $extracted_line =~ freedesktop.org ]] &&
		[[ ! $extracted_line =~ fruitcake.nl ]] &&
		[[ ! $extracted_line =~ getbootstrap.com ]] &&
		[[ ! $extracted_line =~ getcomposer.org ]] &&
		[[ ! $extracted_line =~ getpostman.com ]] &&
		[[ ! $extracted_line =~ getpsalm.org ]] &&
		[[ ! $extracted_line =~ git-scm.com ]] &&
		[[ ! $extracted_line =~ github.com ]] &&
		[[ ! $extracted_line =~ github.io ]] &&
		[[ ! $extracted_line =~ githubusercontent.com ]] &&
		[[ ! $extracted_line =~ gitlab.com ]] &&
		[[ ! $extracted_line =~ gitter.im ]] &&
		[[ ! $extracted_line =~ gnu.org ]] &&
		[[ ! $extracted_line =~ goftino.com ]] &&
		[[ ! $extracted_line =~ goo.gl ]] &&
		[[ ! $extracted_line =~ google.com ]] &&
		[[ ! $extracted_line =~ gophp71.org ]] &&
		[[ ! $extracted_line =~ gov.ua ]] &&
		[[ ! $extracted_line =~ guzzlephp.org ]] &&
		[[ ! $extracted_line =~ hackerone.com ]] &&
		[[ ! $extracted_line =~ haxx.se ]] &&
		[[ ! $extracted_line =~ helm.shpackagemanager ]] &&
		[[ ! $extracted_line =~ httpoxy.org ]] &&
		[[ ! $extracted_line =~ httplug.io ]] &&
		[[ ! $extracted_line =~ iana.org ]] &&
		[[ ! $extracted_line =~ ibm.com ]] &&
		[[ ! $extracted_line =~ icanhazip.com ]] &&
		[[ ! $extracted_line =~ icons8.com ]] &&
		[[ ! $extracted_line =~ ietf.org ]] &&
		[[ ! $extracted_line =~ ifttt.com ]] &&
		[[ ! $extracted_line =~ igor.io ]] &&
		[[ ! $extracted_line =~ iis.net ]] &&
		[[ ! $extracted_line =~ informit.com ]] &&
		[[ ! $extracted_line =~ instagram.com ]] &&
		[[ ! $extracted_line =~ ip-api.com ]] &&
		[[ ! $extracted_line =~ issuehunt.io ]] &&
		[[ ! $extracted_line =~ jenssegers.com ]] &&
		[[ ! $extracted_line =~ jetbrains.com ]] &&
		[[ ! $extracted_line =~ jquery.com ]] &&
		[[ ! $extracted_line =~ jquery.org ]] &&
		[[ ! $extracted_line =~ jsdelivr.net ]] &&
		[[ ! $extracted_line =~ jsperf.com ]] &&
		[[ ! $extracted_line =~ keepachangelog.com ]] &&
		[[ ! $extracted_line =~ kubeprod.io ]] &&
		[[ ! $extracted_line =~ kubernetes.io ]] &&
		[[ ! $extracted_line =~ kirschbaumdevelopment.com ]] &&
		[[ ! $extracted_line =~ laracasts.com ]] &&
		[[ ! $extracted_line =~ laravel.com ]] &&
		[[ ! $extracted_line =~ laravel-news.com ]] &&
		[[ ! $extracted_line =~ lendio.com ]] &&
		[[ ! $extracted_line =~ letsencrypt.org ]] &&
		[[ ! $extracted_line =~ les-tilleuls.coop ]] &&
		[[ ! $extracted_line =~ lifewire.com ]] &&
		[[ ! $extracted_line =~ linkedin.com ]] &&
		[[ ! $extracted_line =~ lnav.org ]] &&
		[[ ! $extracted_line =~ localhost ]] &&
		[[ ! $extracted_line =~ loggly.com ]] &&
		[[ ! $extracted_line =~ magento.com ]] &&
		[[ ! $extracted_line =~ mail.com ]] &&
		[[ ! $extracted_line =~ mailerlite.com ]] &&
		[[ ! $extracted_line =~ makereadme.com ]] &&
		[[ ! $extracted_line =~ mandrillapp.com ]] &&
		[[ ! $extracted_line =~ many.co.uk ]] &&
		[[ ! $extracted_line =~ mariadb.com ]] &&
		[[ ! $extracted_line =~ mariadb.org ]] &&
		[[ ! $extracted_line =~ markido.com ]] &&
		[[ ! $extracted_line =~ mathiasbynens.be ]] &&
		[[ ! $extracted_line =~ meandisreleasedundertheMITLicense ]] &&
		[[ ! $extracted_line =~ medium.com ]] &&
		[[ ! $extracted_line =~ metacpan.org ]] &&
		[[ ! $extracted_line =~ metrix.ir ]] &&
		[[ ! $extracted_line =~ microsoft.com ]] &&
		[[ ! $extracted_line =~ mockery.io ]] &&
		[[ ! $extracted_line =~ mongodb.com ]] &&
		[[ ! $extracted_line =~ mongodb.org ]] &&
		[[ ! $extracted_line =~ mozilla.org ]] &&
		[[ ! $extracted_line =~ mysql.com ]] &&
		[[ ! $extracted_line =~ nesbot.com ]] &&
		[[ ! $extracted_line =~ nextjs.org ]] &&
		[[ ! $extracted_line =~ newrelic.com ]] &&
		[[ ! $extracted_line =~ nginx.com ]] &&
		[[ ! $extracted_line =~ no-color.org ]] &&
		[[ ! $extracted_line =~ nodejs.org ]] &&
		[[ ! $extracted_line =~ nouvelobs.com ]] &&
		[[ ! $extracted_line =~ op.gg ]] &&
		[[ ! $extracted_line =~ opencollective.com ]] &&
		[[ ! $extracted_line =~ opengroup.org ]] &&
		[[ ! $extracted_line =~ opensource.org ]] &&
		[[ ! $extracted_line =~ oracle.com ]] &&
		[[ ! $extracted_line =~ paragonie.com ]] &&
		[[ ! $extracted_line =~ packagist.com ]] &&
		[[ ! $extracted_line =~ packagist.org ]] &&
		[[ ! $extracted_line =~ parceljs.org ]] &&
		[[ ! $extracted_line =~ patreon.com ]] &&
		[[ ! $extracted_line =~ phar.io ]] &&
		[[ ! $extracted_line =~ percona.com ]] &&
		[[ ! $extracted_line =~ phpdoc.org ]] &&
		[[ ! $extracted_line =~ php.net ]] &&
		[[ ! $extracted_line =~ php-fig.org ]] &&
		[[ ! $extracted_line =~ phpstan.org ]] &&
		[[ ! $extracted_line =~ phpunit.de ]] &&
		[[ ! $extracted_line =~ pivotaltracker.com ]] &&
		[[ ! $extracted_line =~ porsline.ir ]] &&
		[[ ! $extracted_line =~ prometheus.io ]] &&
		[[ ! $extracted_line =~ promisesaplus.com ]] &&
		[[ ! $extracted_line =~ psalm.dev ]] &&
		[[ ! $extracted_line =~ pugx.org ]] &&
		[[ ! $extracted_line =~ pusher.com ]] &&
		[[ ! $extracted_line =~ pushover.net ]] &&
		[[ ! $extracted_line =~ pypi.org ]] &&
		[[ ! $extracted_line =~ python.org ]] &&
		[[ ! $extracted_line =~ ramsey.dev ]] &&
		[[ ! $extracted_line =~ readthedocs.io ]] &&
		[[ ! $extracted_line =~ readthedocs.org ]] &&
		[[ ! $extracted_line =~ realfavicongenerator.net ]] &&
		[[ ! $extracted_line =~ redis.io ]] &&
		[[ ! $extracted_line =~ registry.npmjs ]] &&
		[[ ! $extracted_line =~ relay.so ]] &&
		[[ ! $extracted_line =~ repman.io ]] &&
		[[ ! $extracted_line =~ robertbasic.com ]] &&
		[[ ! $extracted_line =~ rfc-editor.org ]] &&
		[[ ! $extracted_line =~ sagikazarmark.hu ]] &&
		[[ ! $extracted_line =~ sailsjs.com ]] &&
		[[ ! $extracted_line =~ sallar.meandisreleasedundertheMITLicense ]] &&
		[[ ! $extracted_line =~ samanepay.com ]] &&
		[[ ! $extracted_line =~ scrutinizer-ci.com ]] &&
		[[ ! $extracted_line =~ sektioneins.de ]] &&
		[[ ! $extracted_line =~ seld.be ]] &&
		[[ ! $extracted_line =~ sendgrid.com ]] &&
		[[ ! $extracted_line =~ sentry.dev ]] &&
		[[ ! $extracted_line =~ sentry.io ]] &&
		[[ ! $extracted_line =~ semver.org ]] &&
		[[ ! $extracted_line =~ shepherd.dev ]] &&
		[[ ! $extracted_line =~ shields.io ]] &&
		[[ ! $extracted_line =~ silverstripe.org ]] &&
		[[ ! $extracted_line =~ sizzlejs.com ]] &&
		[[ ! $extracted_line =~ slack.com ]] &&
		[[ ! $extracted_line =~ snowpack.dev ]] &&
		[[ ! $extracted_line =~ sourcemaking.com ]] &&
		[[ ! $extracted_line =~ spdx.org ]] &&
		[[ ! $extracted_line =~ spiral ]] &&
		[[ ! $extracted_line =~ spotlightjs.com ]] &&
		[[ ! $extracted_line =~ sqlite.org ]] &&
		[[ ! $extracted_line =~ sqlteam.com ]] &&
		[[ ! $extracted_line =~ stackexchange.com ]] &&
		[[ ! $extracted_line =~ stackoverflow.com ]] &&
		[[ ! $extracted_line =~ static::HOST ]] &&
		[[ ! $extracted_line =~ styleci.io ]] &&
		[[ ! $extracted_line =~ symfony.com ]] &&
		[[ ! $extracted_line =~ t.me ]] &&
		[[ ! $extracted_line =~ telegram.me ]] &&
		[[ ! $extracted_line =~ telegram.org ]] &&
		[[ ! $extracted_line =~ thephp.cc ]] &&
		[[ ! $extracted_line =~ thephpleague.com ]] &&
		[[ ! $extracted_line =~ tidelift.com ]] &&
		[[ ! $extracted_line =~ tighten.co ]] &&
		[[ ! $extracted_line =~ till.im ]] &&
		[[ ! $extracted_line =~ timacdonald.me ]] &&
		[[ ! $extracted_line =~ tldp.org ]] &&
		[[ ! $extracted_line =~ tnyholm.se ]] &&
		[[ ! $extracted_line =~ travis-ci.com ]] &&
		[[ ! $extracted_line =~ twitter.com ]] &&
		[[ ! $extracted_line =~ ietf.org ]] &&
		[[ ! $extracted_line =~ toptal.com ]] &&
		[[ ! $extracted_line =~ travis-ci.org ]] &&
		[[ ! $extracted_line =~ unicode.org ]] &&
		[[ ! $extracted_line =~ unpkg.com ]] &&
		[[ ! $extracted_line =~ v8.dev ]] &&
		[[ ! $extracted_line =~ vanderven.se ]] &&
		[[ ! $extracted_line =~ vehikl.com ]] &&
		[[ ! $extracted_line =~ w3.org ]] &&
		[[ ! $extracted_line =~ whatwg.org ]] &&
		[[ ! $extracted_line =~ webdock.io ]] &&
		[[ ! $extracted_line =~ webmozarts.com ]] &&
		[[ ! $extracted_line =~ webkit.org ]] &&
		[[ ! $extracted_line =~ webhook.site ]] &&
		[[ ! $extracted_line =~ webreinvent.com ]] &&
		[[ ! $extracted_line =~ wikihow.com ]] &&
		[[ ! $extracted_line =~ wikipedia.org ]] &&
		[[ ! $extracted_line =~ windows-commandline.com ]] &&
		[[ ! $extracted_line =~ wiredtiger.com ]] &&
		[[ ! $extracted_line =~ wkhtmltopdf.org ]] &&
		[[ ! $extracted_line =~ wordpress.org ]] &&
		[[ ! $extracted_line =~ xdebug.org ]] &&
		[[ ! $extracted_line =~ yarnpkg.com ]] &&
		[[ ! $extracted_line =~ youtube.com ]] &&
		[[ ! $extracted_line =~ zend.com ]] &&
		[[ ! $extracted_line =~ zlib.net ]]; then
        echo "$extracted_line" >> cleaner.log
    fi
done
echo "Finished looking for URLs"
sed -i 's/[ "]//g; s/[)]//g; s/[,]//g; s/[""]//g' cleaner.log
sed -i 's/\/$//' "cleaner.log"
sort cleaner.log | uniq > url.log
rm extractor.log cleaner.log 
echo "Cleanup finished! check url.log"