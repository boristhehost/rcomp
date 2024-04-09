# rcomp

rcomp is  wrapper of `rclone copy` with added support for compressed archive ie to archive the contents before uploading and option to extract the contents after downloading
&nbsp;

### Dependencies

1. Needs bash so it works in unix systems
2. rclone
3. zip
4. 7zip

&nbsp;

### Setup

Copy the rcomp.sh file to /usr/local/bin or add it to environment path and remove the .sh extension and make sure that the file is executable

&nbsp;

### Flags

- `-d|--download` : to download files from remote to host
- `-e|--extract` : to extract the archived zipped files after downloading them and finally removing archived version
- `-n|--name` : to give name of archive zip file. Make sure that custom name dont include spaces between them. Default name is `archive.zip`.
  
  Eg: `rcomp ./local remote_cloud:/rcomp  --name=custom`
  
  No need to include the `.zip` at last
- `--passargs` : to pass arguments to zip command like splitting them or excuding some files or folders.
- other arguments can also be added and they will concatenated with rclone

&nbsp;

### Examples

Let there be a directory named `local` in the current directory and remote directory named `remote_cloud:/rcomp`. Here `remote:cloud` is the rclone config name for some particular cloud and `rcomp` is the remote directory.

- To simply copy the files from local to remote aka upload
  `rcomp ./local remote_cloud:/rcomp`
- To copy files from remote to local aka download
  `rcomp remote_cloud:/rcomp ./local -d -e` (to download archived version then extract them. if extraction not needed then remote the `-e` flag)
- Excluding folders like node_modules or hidden directories(starting with dot)
  We need to use --passargs flag for that to pass argument to zip command
  `rcomp ./local remote_cloud:/rcomp --passargs="-x '*/node_modules/*' -x '*/.*/*'"`
- Splitting files with each part max size being 2 MB
   `rcomp ./local remote_cloud:/rcomp --passargs= "-s 2m"`
