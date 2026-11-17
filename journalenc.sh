# /usr/bin/bash

# JOURNAL ENCRYPTOR

###### FUNCTIONS #######
exists() {

	local dir=$1

	# check if the directory exists
	if [ -e ${dir} ]; then

		# check if the directory is empty
		if [ -z "$(ls -A ${dir})" ]; then

			echo "${dir} is empty!! Aborting..."
			return 1 # sets the exit status viz. $? to 1

		else # directory is not empty

			return 0 # sets the exit status viz. $? to 0

		fi

	fi

	echo "${dir} doesn't exist! Aborting..."
	return 1 # sets the exit status viz. $? to 1

}

gen_random_hex() {

	local dir=$1
	local folders=("$@")
	local folder_exists_status=1

	# will be returned from here
	local key=""
	local iv=""

	for folder in "${folders[@]}"; do

		if [ "${folder}" = "${gpg_folder}" ]; then # the gpg_folder doesn't exist

			folder_exists_status=0
			break

		fi

	done


	# folder doesn't exist
	if [ ${folder_exists_status} -eq 1 ]; then

		# create the gpg_folder
		mkdir -p "${dir}${gpg_folder}"

		key=`openssl rand -hex 16`
		iv=`openssl rand -hex 16`

		# create a text file named keyiv.txt
		touch "${dir}${gpg_folder}keyiv.txt"

		# write the key and iv to the keyiv.txt file
		echo -e "Key: ${key}\nIV: ${iv}" | cat > "${dir}${gpg_folder}keyiv.txt"


		# encrypt it using gpg
		gpg -c "${dir}${gpg_folder}keyiv.txt"

		# remote the plain text file
		rm "${dir}${gpg_folder}keyiv.txt"
	else

		# decrypt the gpg file and extract the key and iv from there
		key=`gpg -d "${dir}${gpg_folder}keyiv.txt.gpg" 2>/dev/null | grep -i "key" | awk '{print $2}'`
		iv=`gpg -d "${dir}${gpg_folder}keyiv.txt.gpg" 2>/dev/null | grep -i "iv" | awk '{print $2}'`

	fi

	echo -e "${key}\n${iv}"

}

encrypt() {

	local key=$1
	local iv=$2
	local folder=$3
	local entry=$4

	# using '.' as a separator between file name and the extension and adding the .bin extension to the filename
	local binary_file_name=`echo "${entry}" | awk -F . '{print $1}'`".bin"

	# check if .bin files already exist in this path
	if [ "$(ls ${dir}${folder} | grep .bin | wc -l)" -ne 0 ]; then

		# if the file exists
		if [ -e "${dir}${folder}${binary_file_name}" ]; then

			# if the binary file is not empty
			if [ -s "${dir}${folder}${binary_file_name}" ]; then

				echo "Encrypted files already exist..."

			else # empty bin files will store the encrypted data

				#encrypt the text file
				openssl enc -aes256 -e -in "${dir}${folder}${entry}" -out "${dir}${folder}${binary_file_name}" -K "${key}" -iv "${iv}" 2>/dev/null

			fi

		else

			openssl enc -aes256 -e -in "${dir}${folder}${entry}" -out "${dir}${folder}${binary_file_name}" -K "${key}" -iv "${iv}" 2>/dev/null

		fi

	else

		openssl enc -aes256 -e -in "${dir}${folder}${entry}" -out "${dir}${folder}${binary_file_name}" -K "${key}" -iv "${iv}" 2>/dev/null

	fi

}

# directory to search for my journals
dir="${HOME}/Desktop/.journal/confidential/"
gpg_folder="journalgpg/"

exists "${dir}"

# if the directory exists and is not empty
if [ $? -eq 0 ]; then

	# make an array that contains all folders inside ${dir}

	# empty array
	folders=()
	i=0
	# add each folder in ${dir} into the ${folders} array
	for folder in `ls "${dir}" | awk '{print $1}'`; do

		# check if the ${folder} is a directory or not; path is very important, so prefixed with ${dir} because ${folder} exists inside ${dir}
		if [ -d "${dir}${folder}" ]; then

			folders[i]="${folder}/"
			((i++)) # C-style incrementation

		fi
	done

fi

# generate the key and initilization vector (IV)
key_and_iv=$(gen_random_hex "${dir}" "${folders[@]}") # passing the array of folders by expanding it into arguments

# extract the key and the iv from the return value
key=`echo ${key_and_iv} | awk '{print $1}'`
iv=`echo ${key_and_iv} | awk '{print $2}'`

# iterate through all the folders
for folder in ${folders[@]}; do

	if [ -z "$(ls -A ${dir}${folder})" ]; then

		echo "${folder} is empty..."
	else

		if [ "${folder}" != "${gpg_folder}" ]; then

			# iterate through all the files in this directory
			for entry in `ls "${dir}${folder}"`; do

				# encrypt the text files
				if [[ "${entry}" == *.txt ]]; then

					encrypt "${key}" "${iv}" "${folder}" "${entry}"

				fi

			done
		fi

	fi

done
