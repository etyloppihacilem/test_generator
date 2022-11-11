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
# TIP: to quickly share the script, use the\033[0;37m -p \033[1;34mflag :)             #
####################################################################\033[0m\n"

majRepo=$(cd $(dirname $(realpath $0)) ; git remote update 2>&1 | grep -o -e "" ; git status -bs | grep -e "#" | grep -o -e ".[0-9]")
if [[ $majRepo ]]; then
	echo -e "\033[1;33m WARN \033[0m: New update avaliable ! Run with the flag\033[0;37m -u \033[0mto update :)"
else
	echo -e "\033[1;32m OK \033[0m: Script is up to date :)\n"
fi

checkMain=1
help_init="Use -i to initialize the repo"
help_run="\n
\n
>> Write your tests into ./test_gen/ and run with -r\n
\n
--------------------------------------------------------------------\n
### TESTFILES :\n
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
The return value is 1 if the test passes succesfully or 0 if not.\n
Functions are supposed to be executed in the same order than in the\n
file, but this is not garanteed.
"


if [ $(basename $(realpath .)) = "test_gen" ]; then
	repo="../"
else
	repo="./"
fi

test_repo=$repo"test_gen/"

get_file_name() {
	echo $(basename $1) | sed "s/TESTER_//g"
}

get_test_name() {
	echo "TESTER_"$(basename $1)
}

get_main_name() {
	echo "MAIN_"$(basename $(get_file_name $1))
}

gen_template() {
	new_file_name=$(get_test_name $1)
	echo "/*
TEST FILE FOR $1
Generated with the test_generator utility
*/

// Write your dependencies after the :
// do not uncomment
//DEPENDENCIES:

#include <stdio.h> // do not remove please

$(ctags -x --fields=nP $1 | sed -e "s/^.*\.c\ *//g" -e "s/$/;/g" -e "s/^static.*//g")

int	T_test1(void)
{
	if (1 == 1)
		return (1);		// the test passes
	return (0);			// the test does not
}" > $test_repo$new_file_name
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
	sed -e "/.*main(/,/}\ \/\/EOAGM/d" -e "/.*main(/,/}/d" $1 > $(get_main_name $1)
	# EOAGM : End Of AutoGenerated Main
	vrai="\033[1;32m OK \033[0m"
	faux="\033[1;31m ERROR \033[0m"
	body=""
	fonctions="$(ctags -x --fields=nP $1 | sed -e "s/^.*\.c\ *//g" -e "s/(.*)/()/g" -e "s/.*\ //g" -e "s/^\**//g")"
	for fonction in $fonctions; do
		body="$body$(echo -e "printf(\"\\\\tTest for %s : %s\\\\n\", \"$(echo $fonction | sed "s/^T_//g")\", $fonction ? \"$vrai\" : \"$faux\");")"
	done
	main="
	int	main(void)
	{
		$body
	}//EOAGM"
	edited=$(cat $(get_main_name $1))$main
	echo "$edited" > $(get_main_name $1)
	additional=$(cat $1 | grep "//DEPENDENCIES:.*" | sed "s/\/\/DEPENDENCIES:\ *//g")
	compilation_logs=$(gcc -Wall -Werror -Wextra $test_repo$(get_main_name $1) $repo$(get_file_name $1) $additional -o $test_repo$(echo $1 | sed "s/\.c/.out/g") 2>&1)
	if [[ $compilation_logs ]]; then
		echo "ERRORS DURING COMPILATION"
		echo $compilation_logs
	else
		echo "$(exec $test_repo$(echo $1 | sed "s/\.c/.out/g"))"
	fi
}

clean() {
	find $test_repo \( -name "MAIN*\.c" -o -name "*\.out" \) -delete
}

while getopts "ihrcpu" opt; do
	case $opt in
		u)
			upd=$(cd $(dirname $(realpath -P $0)) ; git pull -ff)
			echo -e "\033[1;32m OK \033[0m: Script is up to date :)"
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
				echo -e $help_run
			else
				echo -e $help_init
			fi
			;;
		i)
			if [ -d "./test_gen/" ] || [ -d "../test_gen/" ]; then
				echo "Repo already initialized, see -h"
			else
				mkdir test_gen
				if ! [ -f $repo.gitignore ] || ! [ $(cat .gitignore | grep "\./test_gen/\*\*") ]; then
					echo "./test_gen/**" >> $repo.gitignore
				fi
				echo "Repo succesfully initialized"
			fi
			;;
		c)
			for file in $*; do
				if [ $file = "-c" ]; then
					continue
				fi
				if [ $(echo $file | grep "\.c") ] && [ -f $repo$(get_file_name $file) ]; then
					gen_template $file
					echo -e "Template generated for \033[1;33m$(get_file_name $file)\033[0m"
				else
					echo -e "\033[1;31mWrong input\033[0m :/\t\t\033[1;33m$(get_file_name $file)\033[0m"
				fi
			done
			;;
		r)
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

