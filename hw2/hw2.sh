#!/bin/sh

# Define the help message
help_message="\
hw2.sh -p TASK_ID -t TASK_TYPE[-h]

Available Options:

-p: Task id
-t JOIN_NYCU_CSIT|MATH_SOLVER|CRACK_PASSWORD: Task type
-h: Show the script usage"

TASK_ID=""
TASK_TYPE=""
TASK_SERVER="http://10.113.0.253"


while getopts :p:t:h op;do
        case $op in
                p) TASK_ID=$OPTARG ;;
                t) TASK_TYPE=$OPTARG ;;
                h) echo "$help_message"
                   exit 0 ;;
                ?) echo "$help_message" >&2
                   exit 1 ;;
        esac
done

echo "TASK ID: $TASK_ID"
echo "TASK TYPE: $TASK_TYPE"

if [ "$TASK_TYPE" != "JOIN_NYCU_CSIT" ] && [ "$TASK_TYPE" != "MATH_SOLVER" ] && [ "$TASK_TYPE" != "CRACK_PASSWORD" ]; then
        echo "Invalid task type" >&2
        exit 1
fi

RESPONSE=$(curl -s -X GET "$TASK_SERVER/tasks/$TASK_ID")
TASK_type=$(echo "$RESPONSE" | jq -r '.type')
PROBLEM=$(echo "$RESPONSE" | jq -r '.problem')

#echo "Task TYPE: $TASK_type"
#echo "Problem: $PROBLEM"

if [ "$TASK_type" != "$TASK_TYPE" ]; then
        echo "Task type not match" >&2
        exit 1
fi

solve_problem(){
        problem="$1"
        a=0
        b=0
        #c=0
        operator=""
        result=0

        if ! echo "$problem" | grep -qE '^-?[0-9]+ [+-] [0-9]+ = \?$'; then
                echo "Invalid problem"
                return
        fi

        a=$(echo "$problem" | awk '{print $1}')
        operator=$(echo "$problem" | awk '{print $2}')
        b=$(echo "$problem" | awk '{print $3}')
        #c=$(echo "$problem" | awk '{print $5}')

        if [ "$a" -lt -10000 ] || [ "$a" -gt 10000 ] || [ "$b" -lt 0 ] || [ "$b" -gt 10000 ]; then
                echo "Invalid problem"
                return
        fi

        if [ "$operator" = "+" ]; then
                result=$((a + b))
        else
                result=$((a - b))
        fi

        if [ "$result" -lt -20000 ] || [ "$result" -gt 20000 ]; then
                echo "Invalid problem"
                return
        fi

        echo "$result"

}

solve_passwd(){
        problem="$1"
        #first_char=$(echo "$problem" | cut -c1)
        first_char=$(echo "$problem" | awk '{print substr($0, 1, 1)}')
        first_char_ascii=$(printf "%d" "'$first_char")
        N_ascii=$(printf "%d" "'N")
        #echo "$first_char_ascii"
        #echo "$N_ascii"
        offset=$((first_char_ascii - N_ascii))
        #echo "Offset: $offset"

        if [ "$offset" -lt -13 ] || [ "$offset" -gt 13 ]; then
                #offset=$((offset + 26))
                echo "Invalid problem"
                return
        fi

        decrypted=""

        for i in $(seq 1 ${#problem}); do
                char=$(echo "$problem" | awk '{print substr($0, '"$i"', 1)}')
                if echo "$char" | grep -qE '[A-Za-z]'; then
                        char_ascii=$(printf "%d" "'$char")
                        if echo "$char" | grep -qE '[A-Z]'; then
                                base_ascii=$(printf "%d" "'A")
                                new_char_ascii=$(( (char_ascii - base_ascii + 26 - offset) % 26 + base_ascii ))
                        else
                                base_ascii=$(printf "%d" "'a")
                                new_char_ascii=$(( (char_ascii - base_ascii + 26 - offset) % 26 + base_ascii ))
                        fi
                        new_char=$(printf "%b" "$(printf '\\%03o' "$new_char_ascii")")
                        #echo "$new_char"
                        decrypted="$decrypted$new_char"
                else
                        decrypted="$decrypted$char"
                fi
                if [ "$i" -eq 8 ]; then
                        prefix=$(echo "$decrypted" | cut -c 1-8)
                        if [ "$prefix" != "NYCUNASA" ]; then
                                echo "Invalid problem"
                                return
                        fi
                fi
        done
        echo "$decrypted"
}

if [ "$TASK_TYPE" = "MATH_SOLVER" ]; then
        ANSWER=$( solve_problem "$PROBLEM" )
        echo "Answer: $ANSWER"
        SUBMIT_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
        -d "$(jq -n --arg answer "$ANSWER" '{answer: $answer}')" \
        $TASK_SERVER/tasks/"$TASK_ID"/submit)

        echo "Submit Response: $SUBMIT_RESPONSE"
elif [ "$TASK_TYPE" = "JOIN_NYCU_CSIT" ]; then
        ANSWER="I Love NYCU CSIT"
        SUBMIT_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
        -d "$(jq -n --arg answer "$ANSWER" '{answer: $answer}')" \
        $TASK_SERVER/tasks/"$TASK_ID"/submit)
elif [ "$TASK_TYPE" = "CRACK_PASSWORD" ]; then
        ANSWER=$( solve_passwd "$PROBLEM" )
        echo "Answer: $ANSWER"
        #JSON=$(jq -n --arg answer "$ANSWER" '{answer: $answer}')
        #echo "$JSON"
        SUBMIT_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
        -d "$(jq -n --arg answer "$ANSWER" '{answer: $answer}')" \
        $TASK_SERVER/tasks/"$TASK_ID"/submit)
        echo "Submit Response: $SUBMIT_RESPONSE"
fi