#!/bin/bash

show_help() {
    echo "Usage: ./manage_group.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --create           Create user accounts and the group (Default)"
    echo "  --delete           Delete user accounts and the group"
    echo "  --help             Display this help message"
    echo ""
    echo "When using the --create option or without any option, user accounts"
    echo "will be created according to the students.csv file."
    echo ""
    echo "When using the --delete option, user accounts and the group will be deleted"
    echo "according to the students.csv file."
    exit 0
}


create_group() {
	local group_name=$1

	if getent group "$group_name" >/dev/null 2>&1; then
		echo "Skupina ‘$group_name‘ už existuje."
	else
		sudo groupadd "$group_name"
		echo "Skupina ‘$group_name‘ bola vytvorená."
	fi
}

create_user() {
	local rank=$1
	local first_name=$2
	local last_name=$3
	local address=$4
	local uid=$5
	local group_name=$6

	local username="${first_name,,}.${last_name,,}"  # Login vo formáte meno.priezvisko


	if id "$username" >/dev/null 2>&1; then
		echo "Uživatel ‘$username‘ už existuje."
	else
		sudo useradd -m -s /bin/bash -u "$uid" -g "$group_name" -G users,sudo -c "$rank, $first_name $last_name, $address" "$username"
		sudo passwd -d "$username"
		echo "Uživatel ‘$username‘ bol vytvoreny."
		getent passwd "$username" >> user_details.txt
	fi
}

delete_group() {
    local group_name=$1

    if getent group "$group_name" >/dev/null 2>&1; then
        sudo groupdel "$group_name"
        echo "Skupina '$group_name' byla smazána."
    else
        echo "Skupina '$group_name' neexistuje."
    fi
}

delete_user() {
	local first_name=$1
	local last_name=$2

	local username="${first_name,,}.${last_name,,}"

	if id "$username" >/dev/null 2>&1; then
		sudo userdel -r "$username" 2>/dev/null
		echo "Uživatel ‘$username‘ bol zmazaný."
	else 
		echo "Uživatel ‘$username‘ neexistuje."
	fi
}

# Main

operation="create" # Default value

while [[ "$1" != "" ]]; do
    case $1 in
        --create )  operation="create"
                    ;;
        --delete )  operation="delete"
                    ;;
        --help )    show_help
                    ;;
        * )         show_help
                    ;;
    esac
    shift
done


read -p "Zadajte názov vašej študijnej skupiny: " group_name

# Vytvaranie/overovanie iba pri create
if [[ $operation == "create" ]]; then
	create_group "$group_name"
fi



input_file="students.csv"
if [[ ! -f $input_file ]]; then
	echo "Subor ‘$input_file‘ neexistuje."
	exit 1
fi

while IFS=, read -r rank first_name last_name address uid; do
	if [[ $rank == "hodnost" ]]; then # Skipujeme hlavicku
		continue
	fi

	if [[ $operation == "create" ]]; then
		create_user "$rank" "$first_name" "$last_name" "$address" "$uid" "$group_name"
	elif [[ $operation == "delete" ]]; then
		delete_user "$first_name" "$last_name"
	fi

done < "$input_file"

# Zmazanie zadanej groupy pri --delete
if [[ $operation == "delete" ]]; then
	delete_group "$group_name"
fi


