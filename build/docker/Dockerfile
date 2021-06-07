ARG BASE_IMG
FROM $BASE_IMG

# TODO: Find a way to do this without running the 
#       notebook server as root.
USER root

# Create the /Datacube directory 
RUN mkdir /Datacube
RUN chown -R jovyan /Datacube

