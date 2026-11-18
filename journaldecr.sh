#! /usr/bin/bash

exists() {

	local dir=$1

	if [ -e "${dir}" ]; then

		if [ -z "$(ls -A ${dir})" ]; then

			echo "The directory is empty! Aborting..."
			return 1

		else

			return 0

		fi

	fi

	echo "The directory doesn't exist..."
	return 1

}

decrypt() {

	local dir=$1
	local gpg_folder_exists=$2
	local gpg_folder=$3

	if [ ${gpg_folder_exists} -eq 1 ]; then

		echo "Could not find ${gpg_folder}. Aborting..."
		return 1

	fi

	if [ -z "$(ls -A ${dir}${gpg_folder})" ]; then

		echo "${gpg_folder} is empty! Aborting..."
		return 1

	fi

	local -n entry_folders=$4


	# retrieve the key and the iv from the file
	local key=`gpg -d "${dir}${gpg_folder}keyiv.txt.gpg" 2>/dev/null | grep -i "key" | awk '{print $2}'`
	local iv=`gpg -d "${dir}${gpg_folder}keyiv.txt.gpg" 2>/dev/null | grep -i "iv" | awk '{print $2}'`

	# loop through each folder and decrypt each binary file
	for folder in ${entry_folders[@]}; do

		if [ -z "$(ls -A ${dir}${folder})" ]; then

			echo "Empty folder..."

		else

			for entry in `ls "${dir}${folder}"`; do

				if [[ ${entry} == *.bin ]]; then

					text_entry=`echo "${entry}" | awk -F . '{print $1}'`".txt"

					if [ -s "${dir}${folder}/${entry}" ]; then

						openssl enc -aes256 -d -in "${dir}${folder}/${entry}" -out "${dir}${folder}/${text_entry}" -K "${key}" -iv "${iv}" 2>/dev/null
						rm "${dir}${folder}/${entry}"

					fi

				fi

			done

		fi

	done
}

dir="${HOME}/Desktop/.journal/confidential/"
gpg_folder="journalgpg/"
folder_exists_status=1

exists "${dir}"

if [ $? -eq 0 ]; then

	folders=()
	i=0

	for folder in `ls -A "${dir}"`; do

		if [ "${folder}/" != "${gpg_folder}" ]; then

			folders[i]=${folder}
			((i++))

		else

			folder_exists_status=0

		fi

	done

	decrypt "${dir}" "${folder_exists_status}" "${gpg_folder}" folders # passing the array by name

fi
