#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Solicitar el nombre de usuario
echo "Enter your username:"
read USERNAME

# Buscar usuario en la base de datos
USER_INFO=$($PSQL "SELECT user_id, COUNT(game_id), MIN(guess_count) FROM users LEFT JOIN won_user_games ON users.user_id = won_user_games.user_id WHERE username='$USERNAME' GROUP BY users.user_id")

if [[ -z $USER_INFO ]]; then
  # Usuario nuevo
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # Usuario existente
  echo "$USER_INFO" | while IFS="|" read USER_ID GAMES_PLAYED BEST_GAME
  do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# Generar número secreto
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
echo "Guess the secret number between 1 and 1000:"
GUESS_COUNT=0

# Juego de adivinanza
while true; do
  read GUESS

  # Validar que el input es un número
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  ((GUESS_COUNT++))

  if [[ $GUESS -lt $SECRET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  fi
done

# Guardar resultado en la base de datos
INSERT_GAME=$($PSQL "INSERT INTO won_user_games (user_id, guess_count, secret_number) VALUES ($USER_ID, $GUESS_COUNT, $SECRET_NUMBER)")

