# Wallamonitor 
# 10/02/2021

from telegram import Update, ForceReply, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Updater, CommandHandler, MessageHandler, Filters, CallbackContext, CallbackQueryHandler
import mysql.connector
import threading
import requests
import json
import time
import os
from dotenv import load_dotenv
from telegram.utils.helpers import effective_message_type
load_dotenv()

TELEGRAM_TOKEN = os.getenv("TELEGRAM_TOKEN")
MYSQL_HOST= os.getenv("MYSQL_HOST")
MYSQL_USERNAME= os.getenv("MYSQL_USERNAME")
MYSQL_PASSWORD= os.getenv("MYSQL_PASSWORD")
MYSQL_DATABASE= os.getenv("MYSQL_DATABASE")
ARBITRAGE_API= os.getenv("ARBITRAGE_API")
HISTORY_API= os.getenv("HISTORY_API")
ANALYZE_API= os.getenv("ANALYZE_API")


class DatabaseHandler:
    INSERT_USER_QUERY = ("INSERT INTO users "
              "(id) "
              "VALUES (%(id)s)")


    INSERT_USER_COIN_QUERY = """INSERT INTO user_coin (user_id, coin_id) VALUES (%s, (select id from coins where name=%s))"""
    INSERT_USER_EXCHANGE_QUERY = """INSERT INTO user_exchange (user_id, exchange_id) VALUES (%s, (select id from exchanges where name=%s))"""
    SET_USER_STRATEGY_QUERY = """UPDATE users SET id_strategy = (SELECT id FROM strategies WHERE name=%s) WHERE id = %s"""
    GET_MARKETS_QUERY = """SELECT name FROM coins WHERE id NOT IN (SELECT coin_id FROM user_coin WHERE user_id = %s)"""
    GET_USERS_QUERY = ("SELECT id FROM users")
    GET_EXCHANGES_QUERY = """SELECT name FROM exchanges WHERE id NOT IN (SELECT exchange_id FROM user_exchange WHERE user_id = %s)"""
    GET_STRATEGIES_QUERY = ("SELECT name FROM strategies")
    GET_USER_STRATEGY_QUERY = """SELECT name FROM strategies WHERE id IN (SELECT id_strategy FROM users WHERE id = %s)"""
    GET_USER_EXCHANGES_QUERY = """SELECT name FROM exchanges WHERE id IN (SELECT exchange_id FROM user_exchange WHERE user_id = %s)"""
    GET_USER_COINS = ("SELECT name FROM `coins` WHERE id IN (SELECT coin_id FROM user_coin WHERE user_id = %(user_id)s)")
    GET_NOT_USER_COINS = ("SELECT name FROM `coins` WHERE id NOT IN (SELECT coin_id FROM user_coin WHERE user_id = %(user_id)s)")
    CHECK_USER_EXISTS = ("SELECT id FROM users WHERE id = %(user_id)s")
    DELETE_USER_MARKET = """DELETE FROM user_coin WHERE user_id=%s AND coin_id IN (SELECT id FROM coins WHERE name = %s)"""
    DELETE_USER_EXCHANGE = """DELETE FROM user_exchange WHERE user_id=%s AND exchange_id IN (SELECT id FROM exchanges WHERE name = %s)"""


    def connect(self):
        return mysql.connector.MySQLConnection(user=MYSQL_USERNAME, password=MYSQL_PASSWORD,
                                 host=MYSQL_HOST,
                                 database=MYSQL_DATABASE)

    def insert_user(self, id):
        connection = self.connect()
        connection.cursor().execute(self.INSERT_USER_QUERY, {'id':id})
        connection.commit()
        connection.close()

    def get_markets(self, user_id):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.GET_MARKETS_QUERY, (user_id, ))
        return cursor.fetchall()

    def get_exchanges(self, user_id):
        print(user_id)
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.GET_EXCHANGES_QUERY, (user_id, ))
        return cursor.fetchall()

    def get_strategies(self):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.GET_STRATEGIES_QUERY)
        return cursor.fetchall()

    def get_users(self):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.GET_USERS_QUERY)
        return cursor.fetchall()

    def get_user_strategy(self, user_id):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.GET_USER_STRATEGY_QUERY, (user_id, ))
        result = cursor.fetchall()
        return result[0][0]

    def get_user_exchanges(self, user_id):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.GET_USER_EXCHANGES_QUERY, (user_id, ))
        return cursor.fetchall()


    def user_exists(self, user_id):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.CHECK_USER_EXISTS, {'user_id': user_id})
        result = cursor.fetchall()
        if not result:
            return False
        return True

    def insert_user_coin(self, user_id, coin):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.INSERT_USER_COIN_QUERY, (user_id, coin))
        connection.commit()
        connection.close()

    def insert_user_exchange(self, user_id, exchange):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.INSERT_USER_EXCHANGE_QUERY, (user_id, exchange))
        connection.commit()
        connection.close()

    def set_user_strategy(self, user_id, strategy):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.SET_USER_STRATEGY_QUERY, (strategy, user_id))
        connection.commit()
        connection.close()

    def delete_market(self, user_id, market):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.DELETE_USER_MARKET, (user_id, market))
        connection.commit()
        connection.close()

    def delete_exchange(self, user_id, exchange):
        connection = self.connect()
        cursor = connection.cursor()
        cursor.execute(self.DELETE_USER_EXCHANGE, (user_id, exchange))
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
        dispatcher.add_handler(CommandHandler("history", TelegramHandler.generate_history_plot))
        dispatcher.add_handler(CommandHandler("analyze", TelegramHandler.generate_analyzed_plot))
        dispatcher.add_handler(CommandHandler("add_markets", TelegramHandler.create_add_market_keyboard))
        dispatcher.add_handler(CommandHandler("delete_markets", TelegramHandler.create_market_delete_keyboard))
        dispatcher.add_handler(CommandHandler("add_exchanges", TelegramHandler.create_add_exchange_keyboard))
        dispatcher.add_handler(CommandHandler("delete_exchanges", TelegramHandler.create_exchange_delete_keyboard))
        dispatcher.add_handler(CommandHandler("strategy", TelegramHandler.create_strategy_keyboard))
        dispatcher.add_handler(CommandHandler("help", TelegramHandler.send_help_message))
        dispatcher.add_handler(CallbackQueryHandler(TelegramHandler.press_button_callback))
        updater.start_polling()
        updater.idle()

    def send_message(user_id, text):
        TelegramHandler.get_updater().bot.sendMessage(chat_id=user_id, text=text)

    def send_help_message(update, context: CallbackContext):
        TelegramHandler.send_message(update.effective_user.id, text=f"Welcome to CryptoArbitrager BOT. A simple util to be notified about arbitrage oportunities"
                    f" across cryptocurrency markets and several exchanges.\n"
                    f"/start -> Set your preferences and start recibing notifications\n"
                    f"/add_markets -> Add more markets to your preferences\n"
                    f"/delete_markets -> Delete markets\n"
                    f"/add_exchanges -> Add more exchanges to your preferences\n"
                    f"/delete_exchanges -> Delete exchanges\n"
                    f"/strategy -> Change your calculation strategy"
                    f"/history <date init> <time init> <date end> <time end> <market> -> Get a profit history plot\n"
                    f"/analyze <date init> <time init> <date end> <time end> <market> <exchange> -> Analyze the market to get supports/resistances\n")

    def generate_history_plot(update, context):
        try:
            date_init = context.args[0]
            time_init = context.args[1]
            date_end = context.args[2]
            time_end = context.args[3]
            market = context.args[4]
            
            img_data = requests.get(HISTORY_API + "?coin=" + market + "&date_init=" + date_init + "&date_end=" + date_end + "&time_init=" + time_init + "&time_end=" + time_end).content
            with open('picture.png', 'wb') as handler:
                handler.write(img_data)

            context.bot.send_photo(update.effective_chat.id, photo=open('picture.png', 'rb'))
        except:
            update.message.reply_text('ERROR: Bad parameters or no data on given time range')

    def generate_analyzed_plot(update, context):
        try:
            date_init = context.args[0]
            time_init = context.args[1]
            date_end = context.args[2]
            time_end = context.args[3]
            market = context.args[4]
            exchange = context.args[5]
            
            img_data = requests.get(ANALYZE_API + "?coin=" + market + "&date_init=" + date_init + "&date_end=" + date_end + "&time_init=" + time_init + "&time_end=" + time_end + "?exchange=" + exchange).content
            with open('picture.png', 'wb') as handler:
                handler.write(img_data)

            context.bot.send_photo(update.effective_chat.id, photo=open('picture.png', 'rb'))
        except:
            update.message.reply_text('ERROR: Bad parameters or no data on given time range')

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
                strategy = db_handler.get_user_strategy(user[0])
                user_market = db_handler.get_current_user_coins(user[0])
                user_exchanges = db_handler.get_user_exchanges(user[0])
                worth_send = False
                for market in user_market:
                    bot_message += (f"\U0001F534 *{market[0]}*:\n")
                    try:   
                        for api_exchange in json_data[strategy][market[0]]:
                            if TelegramHandler.user_has_exchange(user_exchanges, api_exchange):    
                                worth_send = True
                                bot_message += TelegramHandler.prepare_message(strategy, api_exchange, market[0], json_data)
                                if(len(bot_message) > 4000):
                                    updater.bot.sendMessage(chat_id=user[0], text=bot_message, parse_mode='Markdown')
                                    bot_message = ""
                    except:
                        pass
                if worth_send:
                    updater.bot.sendMessage(chat_id=user[0], text=bot_message, parse_mode='Markdown')
                    worth_send = False
                bot_message = "\U0000203C Arbitrage update\n"
            time.sleep(30)

    def user_has_exchange(exchanges, api_exchanges):
        new_exchanges = []
        for exchange in exchanges:
            new_exchanges.append(exchange[0])
        if set(api_exchanges.split("-")).issubset(set(new_exchanges)):
            return True
        return False

    def prepare_message(strategy, api_exchange, market, json_data):
        if strategy == "basic":
            return (f"  \U000025B6 *{str(api_exchange)}:* MIN -> [{str(json_data[strategy][market][api_exchange]['min_exchange'])}"
                        f" - {str(json_data[strategy][market][api_exchange]['min_value'])}]"
                        f". MAX -> [{str(json_data[strategy][market][api_exchange]['max_exchange'])} - "
                        f"{str(json_data[strategy][market][api_exchange]['max_value'])}]. PROFIT -> {str(json_data[strategy][market][api_exchange]['profit'])}\n")
        else:
            return (f"  \U000025B6 *{str(api_exchange)}:* BTC/USD: -> [{str(json_data['triangular'][market][api_exchange]['btc_usd_exchange'])}"
                        f" - {str(json_data['triangular'][market][api_exchange]['btc_usd_value'])}]"
                        f". USD/X -> [{str(json_data['triangular'][market][api_exchange]['usd_x_exchange'])} - "
                        f"{str(json_data['triangular'][market][api_exchange]['usd_x_value'])}]."
                            f". X/BTC -> [{str(json_data['triangular'][market][api_exchange]['x_btc_exchange'])} - "
                        f"{str(json_data['triangular'][market][api_exchange]['x_btc_value'])}]. PROFIT -> "
                        f"{str(json_data['triangular'][market][api_exchange]['profit'])}\n")
                            

    def press_button_callback(update, _: CallbackContext):
        query = update.callback_query
        db_handler = DatabaseHandler()

        updater = TelegramHandler.get_updater()
        command = query.data.split("|")[0]
        value = query.data.split("|")[1]
        if "MARKET_OK" == command : TelegramHandler.create_exchange_keyboard(update)
        elif "MARKET" == command : db_handler.insert_user_coin(update.effective_user.id, value)
        elif "MARKET_ADD_OK" == command : TelegramHandler.send_message(update.effective_user.id, "Markets have been updated successfully")
        elif "EXCHANGE_OK" == command : TelegramHandler.create_strategy_keyboard(update)
        elif "EXCHANGE_ADD_OK" == command : TelegramHandler.send_message(update.effective_user.id, "Exchanges have been updated successfully")
        elif "EXCHANGE" == command : db_handler.insert_user_exchange(update.effective_user.id, value)
        elif "STRATEGY_OK" == command : TelegramHandler.get_updater().bot.sendMessage(chat_id=update.effective_user.id, text='Everything is ready!')
        elif "STRATEGY" == command : db_handler.set_user_strategy(update.effective_user.id, value)     
        elif "MARKETDEL" == command : db_handler.delete_market(update.effective_user.id, value)
        elif "MARKETDEL_OK" == command : TelegramHandler.send_message(update.effective_user.id, "Markets have been updated successfully")
        elif "EXCHANGEDEL" == command : db_handler.delete_exchange(update.effective_user.id, value)
        elif "EXCHANGEDEL_OK" == command : TelegramHandler.send_message(update.effective_user.id, "Exchanges have been updated successfully")
      
        else: print("Button callback error")
            
            

    def create_keyboard_button(items, command, confirmation_command):
        button_matrix = []
        current_row = []

        i = 0
        for item in items:
            if i > 2:
                button_matrix.append(current_row)
                current_row = []
                i = 0
            i = i + 1
            current_row.append(InlineKeyboardButton(item[0], callback_data=command + "|" + item[0]))
        button_matrix.append(current_row)

        button_matrix.append([InlineKeyboardButton("\U00002714", callback_data=confirmation_command + "|")])
        return button_matrix

    def create_add_market_keyboard(update, context):
        db_handler = DatabaseHandler()
        keyboard = TelegramHandler.create_keyboard_button(db_handler.get_markets(update.effective_user.id), "MARKET", "MARKET_ADD_OK")
        reply_markup = InlineKeyboardMarkup(keyboard)
        message_reply_text = 'Choose the markets you want to add'
        update.message.reply_text(message_reply_text, reply_markup=reply_markup)

    def create_market_delete_keyboard(update, context):
        db_handler = DatabaseHandler()    
        keyboard = TelegramHandler.create_keyboard_button(db_handler.get_current_user_coins(update.effective_user.id), "MARKETDEL", "MARKETDEL_OK")
        reply_markup = InlineKeyboardMarkup(keyboard)
        TelegramHandler.get_updater().bot.sendMessage(chat_id=update.effective_user.id, text='Choose markets you want to delete:', reply_markup=reply_markup)

    def create_market_keyboard(update, context: CallbackContext):
        db_handler = DatabaseHandler()
        keyboard = TelegramHandler.create_keyboard_button(db_handler.get_markets(update.effective_user.id), "MARKET", "MARKET_OK")
        reply_markup = InlineKeyboardMarkup(keyboard)
        message_reply_text = 'Choose the markets you want to add'
        TelegramHandler.get_updater().bot.sendMessage(chat_id=update.effective_user.id, text='Choose markets you want to delete:', reply_markup=reply_markup)

    def create_exchange_keyboard(update):
        db_handler = DatabaseHandler()    
        keyboard = TelegramHandler.create_keyboard_button(db_handler.get_exchanges(update.effective_user.id), "EXCHANGE", "EXCHANGE_OK")
        reply_markup = InlineKeyboardMarkup(keyboard)
        TelegramHandler.get_updater().bot.sendMessage(chat_id=update.effective_user.id, text='Now select the exchanges', reply_markup=reply_markup)

    def create_add_exchange_keyboard(update, context: CallbackContext):
        db_handler = DatabaseHandler()
        keyboard = TelegramHandler.create_keyboard_button(db_handler.get_exchanges(update.effective_user.id), "EXCHANGE", "EXCHANGE_ADD_OK")
        reply_markup = InlineKeyboardMarkup(keyboard)
        message_reply_text = 'Choose the exchanges you want to add'
        update.message.reply_text(message_reply_text, reply_markup=reply_markup)

    def create_exchange_delete_keyboard(update,  context: CallbackContext):
        db_handler = DatabaseHandler()    
        keyboard = TelegramHandler.create_keyboard_button(db_handler.get_user_exchanges(update.effective_user.id), "EXCHANGEDEL", "EXCHANGEDEL_OK")
        reply_markup = InlineKeyboardMarkup(keyboard)
        TelegramHandler.get_updater().bot.sendMessage(chat_id=update.effective_user.id, text='Choose the exchanges you want to delete:', reply_markup=reply_markup)


    def create_strategy_keyboard(update, context: CallbackContext):
        db_handler = DatabaseHandler()    
        keyboard = TelegramHandler.create_keyboard_button(db_handler.get_strategies(), "STRATEGY", "STRATEGY_OK")
        reply_markup = InlineKeyboardMarkup(keyboard)
        TelegramHandler.get_updater().bot.sendMessage(chat_id=update.effective_user.id, text='Now choose the strategy', reply_markup=reply_markup)


    def start(update: Update, context: CallbackContext) -> None:
        db_handler = DatabaseHandler()
        
        user = update.effective_user
        if (db_handler.user_exists(user.id) == False):
            db_handler.insert_user(user.id)
            update.message.reply_markdown_v2(fr'Hi {user.mention_markdown_v2()}\!', reply_markup=ForceReply(selective=True),)
            TelegramHandler.create_market_keyboard(update)
        else:
            update.message.reply_markdown_v2(fr'You have already been suscribed\!', reply_markup=ForceReply(selective=True),)



def main() -> None:
    p = threading.Thread(target=TelegramHandler.monitor)
    p.start()

    TelegramHandler.set_handlers(TelegramHandler.get_updater())

if __name__ == '__main__':
    main()