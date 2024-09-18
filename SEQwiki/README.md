# bioagentsConnect : SEQwiki
Adaptor for content exchange between bio.agents and SEQwiki.

This is a simple mapper written in Python and wrapped with a bash script. The mapper uses the current EDAM version and maps SeqWIKI concepts to this. Only concepts that are found in EDAM are mapped and therefore mapping confidence is high. To assist the user and annotators various text files are printed e.g. to reveal which SeqWIKI concepts that could not be mapped to EDAM. The final output is a JSON file of the SeqWIKI agents.

It is easy to test the script by following the below guide:

1. Download the python2 script "seqwiki2bioagents.py" and the bash script "seqwiki2bioagents_mapper.sh".

2. Be connected to the internet and then run seqwiki2bioagents_mapper.sh.

The bash script will download the latest EDAM version and the required files from SeqWIKI. Then the Python script is started and this will output lists of problematic agents, a simple count stats report and the agents in JSON format.

NOTE: There are some errors in SEQwiki csv's that need to be fixed manually in order to get valid Bioagents Schema XML. See the output of the seqwiki2bioagents.py or xmllint.
