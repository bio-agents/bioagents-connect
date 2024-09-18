# bioagentsConnect : Debian Med
Adaptor for content exchange between bio.agents and Debian Med.

## edam.sh

Run this script on any Linux machine with a psql client.

The script queries the Debian "database of everything" (UDD) and
retrieves, for all bioinformatics agents inside Debian, information
relevant to bio.agents, including EDAM annotations.  The UDD itself
includes information from the debian/upstream/edam files which hold EDAM
annotation on Debian packages.

## edamJson2bioagents.py

This script rewrites the json file exported by edam.sh and places
the annotation of each agent into the folder structure prepared by
bio.agents/content. There is lies next to data provided from other sources
like conda. It will be a task for the bio.agents curators to integrate
it all.
