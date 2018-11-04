#!/bin/sh
BASIC_RULES_URL="https://docs.google.com/spreadsheets/d/e/2PACX-1vQXnLbszryaB5go7Bnl3eRCm8TpEimQTIvVpQ2Ey6Bl0SBPXNcIFv3TL57hvETvcdAism8Q2QL4M9Eh/pub?gid=1136011327&single=true&output=csv"
STAR_RULES_URL="https://docs.google.com/spreadsheets/d/e/2PACX-1vQXnLbszryaB5go7Bnl3eRCm8TpEimQTIvVpQ2Ey6Bl0SBPXNcIFv3TL57hvETvcdAism8Q2QL4M9Eh/pub?gid=152354064&single=true&output=csv"
BASEDIR=$(dirname "$0")
BASIC_CSV="${BASEDIR}/basic_rules.csv"
STAR_CSV="${BASEDIR}/star_rules.csv"
wget ${BASIC_RULES_URL} -O ${BASIC_CSV}
wget ${STAR_RULES_URL} -O ${STAR_CSV}
dos2unix ${BASIC_CSV}
dos2unix ${STAR_CSV}
