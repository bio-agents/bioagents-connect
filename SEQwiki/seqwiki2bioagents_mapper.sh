#!/usr/bin/env bash

echo "Downloading EDAM and the SeqWIKI CSV files"
### Downloads from EDAM:
wget "http://data.bioontology.org/ontologies/EDAM/download?apikey=8b5b7825-538d-40e0-9e9e-5ab9274a9aeb&download_format=csv" -O EDAM.csv.gz
gunzip -f EDAM.csv.gz

### Downloads from SeqWIKI
# First download the agents:
wget "http://seqanswers.com/w/index.php?title=Special:Ask&x=-5B-5BCategory%3ABioinformatics-20application-5D-5D%2F-3FApplication-20score%2F-3FBioinformatics-20method%2F-3FBiological-20domain%2F-3FBiological-20technology%2F-3FCreated-20by%2F-3FEmail-20address%2F-3FInput-20format%2F-3FInstitute%2F-3FInterface%2F-3FLanguage%2F-3FLibrary%2F-3FLicence%2F-3FMaintained%2F-3FNumber-20of-20citations%2F-3FNumber-20of-20references%2F-3FOperating-20system%2F-3FOutput-20format%2F-3FPM-20page-20counter%2F-3FPM-20page-20last-20editor%2F-3FPM-20page-20size%2F-3FResource-20type%2F-3FSoftware-20feature%2F-3FSoftware-20summary%2F-3FModification-20date&limit=2000&format=csv&sep=%2C&headers=show" -O agents.csv

# Then download the references:
wget "http://seqanswers.com/wiki/Special:Ask/-5B-5BCategory:Reference-5D-5D/-3FAuthor/-3FJournal/-3FNumber-20of-20citations/-3FPubmed-20id/-3FReference-20describes/-3FTitle/-3FVolume/-3FYear/-3FModification-20date/limit%3D2000/format%3Dcsv/sep%3D,/headers%3Dshow" -O references.csv


# Lastly get the URLs:
wget "http://seqanswers.com/wiki/Special:Ask/-5B-5BCategory:URL-5D-5D/-3FURL-20describes/-3FURL-20type/-3FModification-20date/-3FURL/limit%3D2000/format%3Dcsv/sep%3D,/headers%3Dshow" -O urls.csv

# Download annotations from the Google Sheet:
wget 'https://docs.google.com/spreadsheets/d/1qE5DM8_oVRL6X5NBm5ohSozUYuEKMjjQtAGdM-3mkqc/export?format=csv' -O annotations.csv
sed -i '1d' annotations.csv

# Remove errorneous HTML messages from the head of SEQwiki csv's
sed -i '/^<b/d' agents.csv
sed -i '/^<b/d' references.csv
sed -i '/^<b/d' urls.csv


### Do the mapping
echo
echo "Now starts the mapping of SeqWIKI to bioagents JSON format"

# Print the mixed concepts to a file:
#python2 seqwiki2bioagents.py -agent agents.csv -ref references.csv -url urls.csv -edam EDAM.csv -mix 1 | sort > seqwiki_mixed_concepts_sorted.txt

# Print the mismatching concepts to a file:
#python2 seqwiki2bioagents.py -agent agents.csv -ref references.csv -url urls.csv -edam EDAM.csv -mis 1 | sort > seqwiki_mismatching_concepts_sorted.txt

# Print the missing agent names to a file:
#python2 seqwiki2bioagents.py -agent agents.csv -ref references.csv -url urls.csv -edam EDAM.csv -nokey 1 > seqwiki_missing_agent_names.txt

# Dump the agents in JSON format and XML
python2 seqwiki2bioagents.py -agent agents.csv -ref references.csv -url urls.csv -edam EDAM.csv -out seqwiki_dump.json -stats seqwiki_dump.stats -v 1
