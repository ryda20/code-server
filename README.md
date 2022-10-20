Code-server is a docker template to run (vs) code server inside docker.
Base on Alpine Linux

Github Repos:

	https://github.com/ryda20/code-server

Dev Requirements:

	https://github.com/ryda20/Taskfile

Note: now just focus on Dockerfile, rootless and s6 are not doing yet!

#  How to use:
- get docker image at: ryda20/code-server:latest
- run command: `docker run -p 8080:8080 ryda20/code-server`
- another options:
	- `8080`: code server port in container
	- `/workspace`: workspace folder
	- `/config`: code server config folder (data, extension)
	- `/dotfiles`: you can mount your dotfiles here, it will auto link all dot files to home dir /stduser (ln -s). Run under root user
	- `/autorunscripts`: auto run your script at startup here, the entry point will look at this directory and find all files with name run_me.sh and run it (set +x for it first). Run under root user
	- `PASSWORD`: env to set code server password 
	- `PROXY_DOMAIN`: env to set domain

# Note:
1. `/app/code-server/lib/vscode/product.json`: path to product.json
2. You can mount any application this this container for your programming. Example golang programming:
```sh
		go_bin_source/go:/usr/local/go/
		go_pkg_folder/go:/stduser/go/
```
