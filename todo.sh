#!/bin/bash

# Set the path for the .todo file
TODO_FILE="$HOME/.todo"

# Function to add an item to the todo list
add_item () {
  # Get the current item number
  item_num=$(tail -n1 "$TODO_FILE" | awk -F '|' '{print $1}')
  if [ -z "$item_num" ]; then
    item_num=1
  else
    item_num="$((item_num + 1))"
  fi

  # Get the task text and encode special characters
  task=$(echo "$1" | sed 's/|/\\|/g; s/\n/\\n/g')

  # Get the current timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  # Add the item to the todo list
  printf '%s|%s|%s|%s\n' "$item_num" "todo" "$timestamp" "$task" >> "$TODO_FILE"
}

# Function to display the todo list
display_list () {
  # Filter the list based on the status argument
  if [ "$1" == "todo" ]; then
    grep '^[0-9]*|todo|' "$TODO_FILE" | sort -k4,4n
  elif [ "$1" == "doing" ]; then
    grep '^[0-9]*|doing|' "$TODO_FILE" | sort -k4,4n
  elif [ "$1" == "done" ]; then
    grep '^[0-9]*|done|' "$TODO_FILE" | sort -k4,4n
  else
    cat "$TODO_FILE" | sort -k4,4n
  fi
}

# Function to update the status of an item
update_status () {
  # Get the item number and new status
  item_num="$1"
  new_status="$2"

  # Check if the item number exists in the todo list
  item_line=$(grep "^$item_num|" "$TODO_FILE")
  if [ -z "$item_line" ]; then
    echo "Error: item $item_num does not exist."
    exit 1
  fi

  # Get the task text, timestamp, and old status
  task=$(echo "$item_line" | awk -F '|' '{print $3}' | sed 's/\\|/|/g; s/\\n/\n/g')
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  old_status=$(echo "$item_line" | awk -F '|' '{print $2}')

  # Replace the item line with the updated status
  sed -i "s/^$item_num|$old_status|.*|.*/$item_num|$new_status|$timestamp|$task/" "$TODO_FILE"
}


# Function to refactor the item numbers
refactor_list() {
  if [ -f "$HOME/.todo" ]; then
    temp_file="$(mktemp)"
    item_number=0
    while IFS= read -r line; do
      ((item_number++))
      echo "${item_number}|$line" >> "$temp_file"
    done < "$HOME/.todo"
    mv "$temp_file" "$HOME/.todo"
  fi
}

# Function to clean the todo list
clean_list () {
  # Remove all items with a done status
  grep -v 'done|' "$TODO_FILE" > "$TODO_FILE.tmp"
  mv "$TODO_FILE.tmp" "$TODO_FILE"
}

# Main

# Check if the todo file exists, if not create it
if [ ! -f "$HOME/.todo" ]; then
  echo "item_number|status|timestamp|task" > "$HOME/.todo"
fi

# Parse command line arguments
case "$1" in
  add)
    # Add a new todo item
    shift
    add_item "$*"
    ;;
  list)
    # List all non-done todo items
    display_list
    ;;
  listdone)
    # List all done todo items
    display_list "done"
    ;;
  listdoing)
    # List all doing todo items
    display_list "doing"
    ;;
  listtodo)
    # List all todo todo items
    display_list "todo"
    ;;
  do)
    # Update a todo item to doing
    update_status "$2" "doing"
    ;;
  done)
    # Update a todo item to done
    update_status "$2" "done"
    ;;
  undo)
    # Update a todo item to todo
    update_status "$2" "todo"
    ;;
  clean)
    # Clean the todo list
    clean_list
    ;;
  refactor)
    # Refactor the item numbers
    refactor_list
    ;;
  *)
    # Show usage information
    echo "Usage: todo.sh [add task | list | listdone | listdoing | listtodo | do item_number | done item_number | undo item_number | clean | refactor]"
    ;;
esac
