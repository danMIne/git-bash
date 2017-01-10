

# Delete all local branchs excepts current  -version1.0.0
purerepo(){
	mkdir -p .git/refs/.shadow/heads
	rm -f .git/refs/.shadow/heads/*
	cp -R -p .git/refs/heads/. .git/refs/.shadow/heads/	
	case $? in
	0)
		__pureaction
		__output $?
		;;
	1)
		echo Failed to backup branches, continue?\(Y/N\)
		read varchoice
		if [ $varchoice = Y ] || [ $varchoice = y ]
		then
			__pureaction
			__output $?
		elif [ $varchoice = N ] || [ $varchoice = n ]
		then
			echo Exsist!......
		else
			echo Unknown input! Exsit!......
		fi
		;;
	*)
		echo Error!!!! Exsist!...... $?
		;;
	esac		
}

__pureaction(){
	git fetch -p
	git branch -l | grep -v "\*" | xargs -r -n 1 git branch -D	
}


__output(){
	case $1 in
	0)
	  echo Succeed!
	  ;;
	1)
	  echo Failed!
	  ;;
	*)
	  echo $1
	  echo Error!
	  ;;
	esac
}

revertpure(){
	cp -R -p -u .git/refs/.shadow/heads/. .git/refs/heads/
	case $? in
	0)
		rm .git/refs/.shadow/heads/*
		__output $?
		;;
	*)
		__output $?
		;;
	esac
}