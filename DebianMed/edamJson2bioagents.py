#!/usr/bin/python3
import argparse
import os
import json
import logging
from pathlib import Path
import yaml

verbose = False

##### NO EDITS BELOW THIS LINE ######


def process_data(input_json, output_dir):
    f = open(input_json, "r")
    j = json.load(f)
    no = 0
    for package in j:
        no = no + 1
        source = package["source"]
        binary = package["package"]
        bioagents = package["bio.agents"]
        agent_info = {}
        if source == binary:
            if bioagents is None:
                pstr = os.path.join(output_dir, source.lower())
                p = Path(pstr)
                if p.is_dir():
                    logging.warning(
                        f"package '{source}' has no bio.agents ref but bio.agents has a cognate one."
                    )
                else:
                    logging.warning(f"package '{source}' has no bio.agents ref.")
            else:
                pstr = os.path.join(output_dir, bioagents.lower())
                p = Path(pstr)
                if not p.is_dir():
                    logging.warning(
                        f"package '{source}' has a bioagents ref ('{bioagents}') but no folder exists."
                    )
                else:
                    doi = package["doi"]
                    if verbose:
                        print(no, source, bioagents)
                    out = open(
                        os.path.join(pstr, f"{bioagents.lower()}.debian.yaml"), "w"
                    )
                    identifiers = {}
                    if bioagents is not None:
                        identifiers["bioagents"] = bioagents.lower()
                    if doi is not None:
                        identifiers["doi"] = [doi]
                    if source is not None:
                        identifiers["debian"] = source
                    bioconda = package["bioconda"]
                    if bioconda is not None:
                        identifiers["bioconda"] = bioconda
                    scicrunch = package["SciCrunch"]
                    if scicrunch is not None:
                        identifiers["scicrunch"] = scicrunch
                    omicagents = package["OMICagents"]
                    if omicagents is not None:
                        identifiers["omicagents"] = omicagents
                    if package.get("biii") is not None:
                        identifiers["biii"] = package.get("biii")
                    if bool(identifiers):
                        agent_info["identifiers"] = identifiers
                    agent_info["homepage"] = package["homepage"]
                    if package.get("license") not in [None, "unknown", "<license>"]:
                        agent_info["license"] = package.get("license")
                    agent_info["summary"] = package.get("description")
                    agent_info["description"] = " ".join(
                        package.get("long_description").split()
                    )
                    agent_info["version"] = package.get("version")
                    agent_info["edam"] = {}
                    agent_info["edam"]["version"] = "unknown"
                    if "topics" in package:
                        agent_info["edam"]["topics"] = package["topics"]
                    if package.get("edam_scopes") is not None:
                        agent_info["edam"]["scopes"] = []
                        for scope in package.get("edam_scopes"):
                            agent_function = {
                                "name": scope["name"],
                                "function": scope.get(
                                    "function", scope.get("functions")
                                ),
                            }
                            if scope.get("input") is not None:
                                agent_function["input"] = scope.get("input")
                            if scope.get("output") is not None:
                                agent_function["output"] = scope.get("output")
                            agent_info["edam"]["scopes"].append(agent_function)
                    edam_scopes = package["edam_scopes"]
                    yaml.dump(agent_info, out)


def get_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_json", help="path to the initial JSON file")
    parser.add_argument("output_dir", help="path to the output dir")
    return parser


def main():
    parser = get_parser()
    args = parser.parse_args()
    process_data(args.input_json, args.output_dir)


if __name__ == "__main__":
    main()
