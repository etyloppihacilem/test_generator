#!/bin/bash
# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    test_generator.sh                                  :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: hmelica <hmelica@student.42.fr>            +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2022/11/11 17:17:41 by hmelica           #+#    #+#              #
#    Updated: 2022/11/11 17:17:41 by hmelica          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

if [ $(basename $(realpath .)) = "test_gen" ]; then
	repo="../"
else
	repo="./"
fi

test_repo=$repo"test_gen/"

clean() {
	find $test_repo \( -name "TEMP_*" -o -name "MAIN*\.c" -o -name "*\.out" \) -delete
}

server_help(){
	echo "
Use the server command to connect to other packs of testfiles

server [command] [args]

-----------------------
## server push \"commit string\"
Pushes updates under commit
Prompt for commit if no commit string provided

-----------------------
## server pull
Pull from the repo, or if it doen't exist,
add the test repo <link> to your actual repo
If no link provided, a prompte will ask you for one if needed

-----------------------
## server list
List recommended repositories to download

-----------------------
## server setup
Launch the setup prompt
That prompt is automatically run when config is unavialable
"
}

server_setup(){
	if ! [ $1 ]; then
		echo -en "Please enter the github link\n : "
		read git_uname
	else
		git_uname=$1
	fi
	echo -n "$git_uname" > $conf_file
}

repo_setup(){
	echo coucou
}

read_conf() {
	if [ -f $conf_file ]; then
		git_link=$(cat $conf_file | sed "s/\n//g")
	fi
}

help_init="Use -i to initialize the repo"

if [[ $1 = "server" ]]; then
	clean
	conf_file=$repo".test_config"
	read_conf
	if [[ $2 == "setup" ]]; then
		server_setup
		exit
	elif [[ $2 == "pull" ]]; then
		if ! [ -d "$test_repo" ];then
			echo $help_init
			exit
		fi
		if ! [ -d "$test_repo.git" ]; then
			if [[ $(find $test_repo) != "$test_repo" ]]; then
				echo There is already a non empty repository, remove it before pulling another one
				exit
			fi
			rmdir $test_repo
			if ! [ -f $conf_file ]; then
				server_setup $3
				read_conf
			fi
			git clone $git_link $test_repo
			exit
		else
			cd $test_repo; git pull -ff
			exit
		fi
	elif [[ $2 == "push" ]]; then
		if ! [ -d $test_repo".git" ]; then
			echo "No git repository found in $(realpath $test_repo)"
			echo "Add a git repository and try again"
			exit
		fi
		if [ $3 ]; then
			commit=$3
		else
			echo -en "Enter commit message and press enter\n : "
			read commit
		fi
		cd $test_repo; git add *; git commit -m "$commit"; git push
		exit
	elif [[ $2 == "list" ]]; then
		cat $(dirname $(realpath $0))"/list.txt"
		exit
	else
		server_help
		exit
	fi
fi

echo -e "\033[1;34m####################################################################
# This script was written by\033[1;37m hmelica \033[1;34mto test your projetcs :)      #
# Happy coding !                                                   #
#                                                                  #
# If you like the script, don't forget to star the repo            #
# on github !                                                      #
#                                                                  #
# Do not hesitate to share this repository, but remember using the #
# github link to enable auto-updates.                              #
#                                                                  #
# Use the\033[0;37m -h \033[1;34mflag to display help                                  #
#                                                                  #
# TIP: to quickly share the script, use the\033[0;37m -p \033[1;34mflag :)             #
####################################################################\033[0m\n"

if [[ $1 = "install" ]]; then
	if ! [[ $(grep "alias tester" ~/.zshrc) ]]; then
		echo "alias tester=\"$(realpath $0)\"" >> ~/.zshrc
		echo -e "Alias successfully installed.\nReload terminal using 'source ~/.zshrc'\nRun the script with 'tester'"
	else
		echo -e "Alias already installed, run with 'tester'"
	fi
	exit
fi

help_run="\n
\n
>> Write your tests into ./test_gen/ and run with -r\n
\n
--------------------------------------------------------------------\n
### TEST FILES :\n
--------------------------------------------------------------------\n
Tests files should be named \"TESTER_{realname}.c\"\n\n
You can create one from a template using the -c [filename] command.\n\n
If your tests requires depencies in other files, you need to add a\n
comment like:\n\n
\t//DEPENDENCIES: file.c file1.c file2.c\n\n
The comment can be anywhere in the testfile.\n\n
--------------------------------------------------------------------\n
### TESTS FUNCTIONS :\n
--------------------------------------------------------------------\n
Tests functions should have a prototype like this :\n\n
\tint\tT_{name}(void);\n\n
There may be several test functions in one single test file.\n\n
Return value :\n
--------------\n
The return value is 0 if the test passes succesfully or anything\n
else if not.\n
Functions are supposed to be executed in the same order than in the\n
file, but this is not garanteed.\n
--------------------------------------------------------------------\n
### SHELL TEST FILES :\n
--------------------------------------------------------------------\n
Shell tests files should be named \"SHELL_{realname}.sh\"\n\n
Be careful to have the exec right (chmod +x <file>)\n
You can create one from a template using the -s [filename] command.\n
Exec rights will be automaticly granted.\n\n
Anything written (for example with echo) will be displayed in a\n
single line. Use '\\\\n' to line return, as if you really wanted to\n
print '\\\\n'.
"

pushverif(){
if [ -f "$(dirname $(realpath $0))/../pushverif/pushverif.sh" ]; then
	cd $repo ; ~/pushverif/pushverif.sh -s
fi
}

get_file_name() {
	echo $(basename $1) | sed -e "s/TESTER_//g" -e "s/MAIN_//g" -e "s/SHELL_//g"
}

get_test_name() {
	echo "TESTER_"$(basename $1)
}

get_main_name() {
	echo "MAIN_"$(basename $(get_file_name $1))
}

get_shell_name() {
	echo "SHELL_"$(basename $(get_file_name $1) .c).sh
}

gen_template() {
	new_file_name=$(get_test_name $1)
	fonctions="$(ctags -x --fields=nP $repo$1 | sed -e "s/^.*\.c\ *//g" -e "s/^static.*//g" -e "s/(.*)/()/g" -e "s/()//g" -e "s/.*\ //g" -e "s/^\**//g")"
	echo "/*
TEST FILE FOR $1
Generated with the test_generator utility
*/

// Write your dependencies after the :
// do not uncomment
//DEPENDENCIES:

#include <stdio.h> // do not remove please

$(ctags -x --fields=nP $repo$1 | sed -e "s/^.*\.c\ *//g" -e "s/$/;/g" -e "s/^static.*//g")
" > $test_repo$new_file_name
for i in $fonctions; do
	echo "
// Autogenerated test function for $i
int	T_$i(void)
{
	if ($i())
		return (0);		// the test passes
	return (1);			// the test does not, displays error code
}" >> $test_repo$new_file_name
done
}

do_shell_test() {
	find $test_repo -name "TEMP_*" -exec chmod a+rwx {} ";"
	if [ -f $test_repo$(get_shell_name $1) ]; then
		len=$(($(echo -n $2 | wc -c)-9))
		if [[ $len < 0 ]]; then len=0; fi
		echo -en "\tShell script tests :$(printf "%$len.s" " ") "
		echo -e $($test_repo$(get_shell_name $1) $test_repo$(echo $(get_main_name $1) | sed -e "s/\.c/.out/g") | tr "\n" " ")
	fi
}

do_test() {
	#check for include
	if ! [[ $(cat $1 | grep "#include <stdio\.h>") ]]; then
		echo "You removed the #include <stdio.h> -_-'"
		mv $1 $test_repo"temp"
		echo "#include <stdio.h>" > $1
		cat $test_repo"temp" >> $1
		rm $test_repo"temp"
	fi
	sed -e "/.*main(/,/}\ \/\/EOAGM/d" -e "/.*main(/,/}/d" $1 > $test_repo$(get_main_name $1)
	# EOAGM : End Of AutoGenerated Main
	vrai="\033[1;32m OK \033[0m"
	faux="\033[1;31m KO \033[0m"
	body=""
	fonctions="$(ctags -x --fields=nP $repo$1 | sed -e "s/^.*\.c\ *//g" | grep "T_.*" | sed -e "s/(.*)/()/g" -e "s/.*\ //g" -e "s/^\**//g")"
	for fonction in $fonctions; do
		body="$body$(echo -e "int\tv_$(echo $fonction | sed -e "s/^T_//g" -e "s/()//g") = $fonction;\nprintf(\"\\\\tTest for %s : %s (%d)\\\\n\", \"$(echo $fonction | sed "s/^T_//g")\", v_$(echo $fonction | sed -e "s/^T_//g" -e "s/()//g") ? \"$faux\" : \"$vrai\", v_$(echo $fonction | sed -e "s/^T_//g" -e "s/()//g"));")"
	done
	main="
	int	main(void)
	{
		$body
	}//EOAGM"
	edited=$(cat $test_repo$(get_main_name $1))$main
	echo "$edited" > $test_repo$(get_main_name $1)
	if [[ $(cat $1 | grep "//DEPENDENCIES:.*" | sed "s/\/\/DEPENDENCIES:\ *//g") ]]; then
		additional=$(for f in $(basename -a $(cat $1 | grep "//DEPENDENCIES:.*" | sed "s/\/\/DEPENDENCIES:\ *//g")); do echo $repo$f; done)
	else
		additional=""
	fi
	compilation_logs=$(gcc -fdiagnostics-color=always -Wall -Werror -Wextra $test_repo$(get_main_name $1) $(get_file_name $1) $additional -o $test_repo$(echo $(get_main_name $1) | sed "s/\.c/.out/g") 2>&1)
	if [[ $compilation_logs ]]; then
		echo -e "\n\033[1;31mERRORS DURING COMPILATION\033[0m\n"
		echo -e "$compilation_logs"
	else
		$test_repo$(echo $(get_main_name $1) | sed -e "s/\.c/.out/g")
	fi
	do_shell_test $1 $(echo $fonction | sed "s/^T_//g")
}

while getopts "aihrcpsu" opt; do
	case $opt in
		u)
			upd=$(cd $(dirname $(realpath -P $0)) ; git pull -ff)
			echo -e "\033[1;32m OK \033[0m: Script is up to date :)\n"
			exit
			;;
		p)
			echo -e "\033[1;32m OK \033[0m: repo link copied to clipboard :)"
			echo -n "https://github.com/etyloppihacilem/test_generator.git" | xclip -sel clip
			echo -e " Use it with 
	\033[36mgit clone https://github.com/etyloppihacilem/test_generator.git\033[0m"
			exit
			;;
		h)
			if [ -d "./test_gen/" ] || [ -d "../test_gen/" ]; then
				echo -e $help_run | less
			else
				echo -e $help_init
			fi
			;;
		i)
			majRepo=$(cd $(dirname $(realpath $0)) ; git remote update 2>&1 | grep -o -e "" ; git status -bs | grep -e "#" | grep -o -e ".[0-9]")
			if [[ $majRepo ]]; then
				echo -e "\033[1;33m WARN \033[0m: New update avaliable ! Run with the flag\033[0;37m -u \033[0mto update :)\n"
			else
				echo -e "\033[1;32m OK \033[0m: Script is up to date :)\n"
			fi
			if [ -d "./test_gen/" ] || [ -d "../test_gen/" ]; then
				if ! [ -f $repo.gitignore ] || ! [ $(grep "test_gen/\*\*" $repo.gitignore) ]; then
					echo -e "test_gen\ntest_gen/**\n.test_config" >> $repo.gitignore
				fi
				echo "Repo already initialized, see -h"
			else
				mkdir test_gen
				if ! [ -f $repo.gitignore ] || ! [ $(cat .gitignore | grep "\./test_gen/\*\*") ]; then
					echo -e "test_gen\ntest_gen/**\n.test_config" >> $repo.gitignore
				fi
				echo "Repo succesfully initialized"
			fi
			;;
		s)
			for file in $*; do
				if [ $file = "-s" ]; then
					continue
				fi
				if [ $(echo $file | grep "\.c") ] && [ -f $repo$(get_file_name $file) ]; then
					if [ -f $test_repo$(get_shell_name $file) ]; then
						echo -e "File \033[1;33m$test_repo$(get_shell_name $file)\033[0m already exists. Delete first if you want to create a new one"
					else
						echo "#!/bin/bash
vrai=\"\033[1;32m OK \033[0m\"	# OK with some color
faux=\"\033[1;31m KO \033[0m\"	# KO with different color
if [ \$(basename \$(realpath .)) = \"test_gen\" ]; then		# defines the work repo
	repo=\"../\"
else
	repo=\"./\"
fi
test_repo=\$repo\"test_gen/\"								# defines the test repo (something with test_gen)
# if your script creates files, place them under \$test_repo, and name them after TEMP_* so they will be automatically removed
# the \$1 arg is the .out of the main test, you can for example run it with valgrind 
# uncomment the following line to do so :
# valgrind -s \$1


# Do stuff here


if [ 1 ]; then
	echo -e \$vrai				# the test passes
else
	echo -e \$faux				# the test doesnt
fi
"> $test_repo$(get_shell_name $file)
						chmod +x $test_repo$(get_shell_name $file)
						echo -e "Shell template generated for \033[1;33m$(get_file_name $file)\033[0m"
					fi
				else
					echo -e "\033[1;31mWrong input\033[0m :/\t\t\033[1;33m$(get_file_name $file)\033[0m"
				fi
			done
			;;
		c)
			for file in $*; do
				if [ $file = "-c" ]; then
					continue
				fi
				if [ $(echo $file | grep "\.c") ] && [ -f $repo$(get_file_name $file) ]; then
					if [ -f $test_repo$(get_test_name $file) ]; then
						echo -e "File \033[1;33m$test_repo$(get_test_name $file)\033[0m already exists. Delete first if you want to create a new one"
					else
						gen_template $file
						echo -e "Template generated for \033[1;33m$(get_file_name $file)\033[0m"
					fi
				else
					echo -e "\033[1;31mWrong input\033[0m :/\t\t\033[1;33m$(get_file_name $file)\033[0m"
				fi
			done
			;;
		"a" | "r")
			if [ $1 = "-a" ]; then
				pushverif
			fi
			if [ $2 ]; then
				files=$*
			else
				files=$(find . -name "TESTER_*\.c")
			fi
			for file in $files; do
				if [ $file = "-r" ]; then
					continue
				fi
				if [ $(echo $file | grep "TESTER_.*\.c") ] && [ -f $test_repo$(basename $file) ]; then
					to_test=$test_repo$(basename $file)
				else
					if [ $(echo $(get_test_name $file) | grep "\.c") ] && [ -f $test_repo$(get_test_name $file) ]; then
						to_test=$test_repo$(get_test_name $file)
					else
						echo -e "\033[1;31mNo testfile found\033[0m :(\t\t\033[1;33m$(get_file_name $file)\033[0m"
						continue
					fi
				fi
				echo -e "Processing tests for \033[1;33m$(get_file_name $file)\033[0m"
				do_test $to_test
				clean
			done
			;;
	esac
done

