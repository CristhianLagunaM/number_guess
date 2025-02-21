#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Solicitar el nombre de usuario
echo "Enter your username:"
read USERNAME

# Buscar usuario en la base de datos
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

if [[ -z $USER_ID ]]; then
  # Usuario nuevo
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # Usuario existente - Obtener datos
  USER_DATA=$($PSQL "SELECT COUNT(game_id), MIN(guess_count) FROM won_user_games WHERE user_id='$USER_ID'")

  echo "$USER_DATA" | while IFS="|" read GAMES_PLAYED BEST_GAME
  do
    if [[ -z $BEST_GAME ]]; then
      BEST_GAME="N/A"
    fi
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# Generar número secreto
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
echo "Guess the secret number between 1 and 1000:"

GUESS_COUNT=0
LOWER_BOUND=1
UPPER_BOUND=1000

while true; do
  read GUESS

  # Verificar si el input es un número válido
  if ! [[ "$GUESS" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  ((GUESS_COUNT++))

  if [[ $GUESS -eq $SECRET_NUMBER ]]; then
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
    # Insertar solo si USER_ID es válido
    if [[ -n $USER_ID ]]; then
      INSERT_GAME=$($PSQL "INSERT INTO won_user_games (user_id, guess_count, secret_number) VALUES ($USER_ID, $GUESS_COUNT, $SECRET_NUMBER)")
    else
      echo "Error: User ID not found. Could not save game record."
    fi
    break
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    UPPER_BOUND=$GUESS
    if [[ $((GUESS - SECRET_NUMBER)) -le 10 ]]; then
      echo "You're very close! Try a slightly lower number:"
    else
      echo "It's lower than that, guess again (Try between $LOWER_BOUND and $UPPER_BOUND):"
    fi
  else
    LOWER_BOUND=$GUESS
    if [[ $((SECRET_NUMBER - GUESS)) -le 10 ]]; then
      echo "You're very close! Try a slightly higher number:"
    else
      echo "It's higher than that, guess again (Try between $LOWER_BOUND and $UPPER_BOUND):"
    fi
  fi
done
