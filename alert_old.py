# Wallamonitor 
# 10/02/2021

from telegram import Update, ForceReply, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Updater, CommandHandler, MessageHandler, Filters, CallbackContext, CallbackQueryHandler
import mysql.connector
import threading
import requests
import json

class DatabaseHandler:
    INSERT_USER_QUERY = ("INSERT INTO users "
              "(id) "
              "VALUES (%(id)s)")


    INSERT_USER_COIN_QUERY = """INSERT INTO user_coin (user_id, coin_id) VALUES (%s, %s)"""

    GET_COINS_QUERY = ("SELECT name FROM coins")
    GET_USERS_QUERY = ("SELECT id FROM users")
    GET_COIN_ID_QUERY = """SELECT id FROM coins WHERE name = %s"""
    GET_USER_COINS = ("SELECT name FROM `coins` WHERE id IN (SELECT coin_id FROM user_coin WHERE user_id = %(user_id)s)")
    GET_NOT_USER_COINS = ("SELECT name FROM `coins` WHERE id NOT IN (SELECT coin_id FROM user_coin WHERE user_id = %(user_id)s)")

    def connect(self):
        return mysql.connector.MySQLConnection(user='daniel', password='inspiron123',
                                 host='win.danielhuici.ml',
                                 database='telegram_bot')

    def insert_user(self, id):
        connection = self.connect()
        connection.cursor().execute(self.INSERT_USER_QUERY, {'id':id})
        connection.commit()
        connection.close()

    def get_coins(self):
        print("Get coins")
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.GET_COINS_QUERY)
        return cursor.fetchall()

    def get_users(self):
        print("Get users")
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.GET_USERS_QUERY)
        return cursor.fetchall()

    def insert_user_coin(self, user_id, coin):
        print("Selected coin: " + coin)
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.GET_COIN_ID_QUERY, (coin, ))
        coin_id = cursor.fetchone()
        cursor.execute(self.INSERT_USER_COIN_QUERY, (user_id, coin_id[0]))
        connection.commit()
        connection.close()

    def get_current_user_coins(self, user_id):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.GET_USER_COINS, {'user_id': user_id})
        return cursor.fetchall()

    def get_not_user_coins(self, user_id):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.GET_NOT_USER_COINS, {'user_id': user_id})
        return cursor.fetchall()

class TelegramHaldner:
    def monitor():
        print("Started")
        db_handler = DatabaseHandler()
        users = db_handler.get_users()
        r = requests.get('http://localhost:8080/values')
        json_data = json.loads(r.text)
        updater = Updater("1601753934:AAHi_INxa9Q5MltQe6CeIhrSoWrV35sF4F4")
        bot_message = "Hi! Monitor: "
        print(json_data)
        for user in users:
            print(user[0])
            coins = db_handler.get_current_user_coins(user[0])
            for coin in coins:
                bot_message += "Metemos nueva " + coin[0] + ": " + str(json_data[coin[0]]["profit"])
                updater.bot.sendMessage(chat_id=user[0], text=bot_message)
            updater.bot.sendMessage(chat_id=user[0], text=bot_message)
            bot_message = "Hi! Monitor: "

def start(update: Update, context: CallbackContext) -> None:
    """Send a message when the command /start is issued."""
    print("Holaaaaa")
    db_handler = DatabaseHandler()
    #db_handler.insert_user(update.effective_user.id)
    
    user = update.effective_user
    update.message.reply_markdown_v2(
        fr'Hi {user.mention_markdown_v2()}\!',
        reply_markup=ForceReply(selective=True),
    )

    coins = db_handler.get_coins()

    keyboard = create_keyboard_button(coins)
    #[
    #    [
     #       InlineKeyboardButton("Option 1", callback_data='1'),
     #       InlineKeyboardButton("Option 2", callback_data='2'),
     #   ],
     #   [InlineKeyboardButton("Option 3", callback_data='3')],
    #]
    reply_markup = InlineKeyboardMarkup(keyboard)
    message_reply_text = 'Click one of these buttons'
    update.message.reply_text(message_reply_text, reply_markup=reply_markup)

def press_button_callback(update: Update, _: CallbackContext) :
    query = update.callback_query
    db_handler = DatabaseHandler()

    updater = Updater("1601753934:AAHi_INxa9Q5MltQe6CeIhrSoWrV35sF4F4")
    if query.data == "OK": query.edit_message_text(text=f"OK")
    else:
        db_handler.insert_user_coin(update.effective_user.id, query.data)
        coins = db_handler.get_not_user_coins(update.effective_user.id)
        keyboard = create_keyboard_button(coins)
        reply_markup = InlineKeyboardMarkup(keyboard)
        #updater.bot.sendMessage(chat_id=update.effective_user.id, text='Hello there!')

def create_keyboard_button(coins):
    button_matrix = []
    current_row = []

    i = 0
    for coin in coins:
        if i > 2:
            button_matrix.append(current_row)
            current_row = []
            i = 0
        i = i + 1
        current_row.append(InlineKeyboardButton(coin[0], callback_data=coin[0]))
    button_matrix.append(current_row)

    button_matrix.append([InlineKeyboardButton("\U00002714", callback_data="OK")])
    return button_matrix

def main() -> None:
    p = threading.Thread(target=TelegramHaldner.monitor)
    p.start()
    """Start the bot."""
    # Create the Updater and pass it your bot's token.
    updater = Updater("1601753934:AAHi_INxa9Q5MltQe6CeIhrSoWrV35sF4F4")

    # Get the dispatcher to register handlers
    dispatcher = updater.dispatcher

    # on different commands - answer in Telegram
    dispatcher.add_handler(CommandHandler("start", start))
    dispatcher.add_handler(CallbackQueryHandler(press_button_callback))

    # Start the Bot
    updater.start_polling()

    # Run the bot until you press Ctrl-C or the process receives SIGINT,
    # SIGTERM or SIGABRT. This should be used most of the time, since
    # start_polling() is non-blocking and will stop the bot gracefully.
    updater.idle()
    




if __name__ == '__main__':
    main()