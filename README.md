#  MyMusicServer

MyMusicServer is one module of three that make up the MyMusic System.   It's purpose is to serve audio files, 
image files, and music recording metadata to clients within a household.

MyMusicServer will store metadata, audiofiles, and image files for the system It will be the *source of truth* 
for the music collection.  It will provide a RESTful API for clients to create update and delete this information.
All transactions will be logged with a timestamp, so that clients may sync their local store to the last version
on the server

