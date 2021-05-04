# Wallamonitor 
# 10/02/2021

from telegram import Update, ForceReply, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Updater, CommandHandler, MessageHandler, Filters, CallbackContext, CallbackQueryHandler
import mysql.connector
import threading
import requests
import json
import time
from dotenv import load_dotenv
load_dotenv()

TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN")
MYSQL_HOST= os.getenv("MYSQL_HOST")
MYSQL_USERNAME= os.getenv("MYSQL_USERNAME")
MYSQL_PASSWORD= os.getenv("MYSQL_PASSWORD")
MYSQL_DATABASE= os.getenv("MYSQL_DATABASE")
ARBITRAGE_API= os.getenv("ARBITRAGE_API")


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
    CHECK_USER_EXISTS = ("SELECT id FROM users WHERE id = %(user_id)s")

    def connect(self):
        return mysql.connector.MySQLConnection(user=MYSQL_USERNAME, password=MYSQL_PASSWORD,
                                 host=MYSQL_HOST,
                                 database=MYSQL_DATABASE)

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

    def user_exists(self, user_id):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.CHECK_USER_EXISTS, {'user_id': user_id})
        result = cursor.fetchall()
        print(result)
        if not result:
            return False
        return True

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

class TelegramHandler:
    def get_updater():
        return Updater(TELEGRAM_TOKEN)

    def set_handlers(updater):
        dispatcher = updater.dispatcher
        dispatcher.add_handler(CommandHandler("start", TelegramHandler.start))
        dispatcher.add_handler(CallbackQueryHandler(TelegramHandler.press_button_callback))
        updater.start_polling()
        updater.idle()


    def monitor():
        print("Started")
        db_handler = DatabaseHandler()
        while True:
            users = db_handler.get_users()
            response = requests.get(ARBITRAGE_API)
            json_data = json.loads(response.text)
            updater = TelegramHandler.get_updater()
            bot_message = "\U0000203C Arbitrage update\n"
            for user in users:
                coins = db_handler.get_current_user_coins(user[0])
                for coin in coins:
                    bot_message += (f"\U0001F534 *{coin[0]}*: MÍNIMO ->  {str(json_data[coin[0]]['min_exchange'])}"
                                f"({str(json_data[coin[0]]['min_value'])}) MÁXIMO -> {str(json_data[coin[0]]['max_exchange'])}"
                                f"({str(json_data[coin[0]]['max_value'])}) PROFIT -> {str(json_data[coin[0]]['profit'])}\n")
                updater.bot.sendMessage(chat_id=user[0], text=bot_message, parse_mode='Markdown')
                bot_message = "\U0000203C Arbitrage update\n"
            time.sleep(30)


    def press_button_callback(update, _: CallbackContext):
        query = update.callback_query
        db_handler = DatabaseHandler()

        updater = TelegramHandler.get_updater()
        if query.data == "OK": query.edit_message_text(text=f"OK")
        else:
            db_handler.insert_user_coin(update.effective_user.id, query.data)
            coins = db_handler.get_not_user_coins(update.effective_user.id)
            reply_markup = InlineKeyboardMarkup(TelegramHandler.create_keyboard_button(coins))
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

    def start(update: Update, context: CallbackContext) -> None:
        db_handler = DatabaseHandler()        
        
        user = update.effective_user
        if (db_handler.user_exists(user.id) == False):
            db_handler.insert_user(user.id)
            update.message.reply_markdown_v2(fr'Hi {user.mention_markdown_v2()}\!', reply_markup=ForceReply(selective=True),)
            keyboard = TelegramHandler.create_keyboard_button(db_handler.get_coins())
            reply_markup = InlineKeyboardMarkup(keyboard)
            message_reply_text = 'Choose the coins you want to monitor:'
            update.message.reply_text(message_reply_text, reply_markup=reply_markup)
        else:
            update.message.reply_markdown_v2(fr'You have already been suscribed\!', reply_markup=ForceReply(selective=True),)



def main() -> None:
    p = threading.Thread(target=TelegramHandler.monitor)
    p.start()

    TelegramHandler.set_handlers(TelegramHandler.get_updater())

if __name__ == '__main__':
    main()