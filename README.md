# OCR-D Controller

> Path to network implementation of OCR-D

1. In the simplest (and current) form, the controller will be a SSH login server for a full [command-line](https://ocr-d.de/en/spec/cli) [OCR-D](https://ocr-d.de) [installation](https://github.com/OCR-D/ocrd_all). 
   Files must be mounted locally (if they are network shares, this must be done on the host side running the container).
2. Next, the SSH server can also dynamically receive and send data.
3. The first true network implementation will offer an HTTP interface for processing (like the workflow server).
4. From there, the actual processing could be further delegated into different processing servers.
5. A more powerful workflow engine would then offer instantiating different workflows, and monitoring jobs.
6. In the final form, the controller will implement (most parts of) the OCR-D Web API.

## Usage

Build or pull the Docker image:

    make build # or docker pull

Then run the container – providing host-side directories for the volumes `DATA` and `MODELS`, but also a (multi-line) string `KEYS` with public key credentials:

    make run DATA=/mnt/workspaces MODELS=~/.local/share KEYS=$(cat ~/.ssh/id_rsa.pub) PORT=8022

Then you can log in from remote (but let's use `localhost` for the example):

    ssh -p 8022 localhost "ocrd-import -P some-document"

For actual processing, you will first need to download some models into your `MODELS` volume:

    ssh -p 8022 localhost "ocrd resmgr download ocrd-tesserocr-recognize *"

Subsequently, you can use these models on your `DATA` files:

    ssh -p 8022 localhost "ocrd process -m some-document/mets.xml 'tesserocr-recognize -P segmentation_level region -P model Fraktur'"
    # or equivalently:
    ssh -p 8022 localhost "ocrd-tesserocr-recognize -m some-document/mets.xml -P segmentation_level region -P model Fraktur"

For parallel processing, you can either
- run multiple processes on a single controller by
  - logging in multiple times, or 
  - issueing parallel commands (via basic shell scripting or [ocrd-make](https://bertsky.github.io/workflow-configuration) calls)
- run processes on multiple controllers.

Apart from the SSH server, this currently also exposes a [webserver](https://github.com/OCR-D/ocrd-website/wiki/browse-ocrd-in-Docker) for the [OCR-D browser](https://github.com/hnesk/browse-ocrd) installed in the container:

    browse-ocrd some-document/mets.xml

You can then access `localhost:8085` with your browser for the GUI.

