import sys
# import pickle
import logging
from decimal import Decimal, setcontext, BasicContext, InvalidOperation
from datetime import datetime

from bank import Bank, Base
from exceptions import OverdrawError, TransactionLimitError, TransactionSequenceError

import sqlalchemy
from sqlalchemy.orm.session import sessionmaker

import tkinter as tk


# context with ROUND_HALF_UP
setcontext(BasicContext)

logging.basicConfig(filename='bank.log', level=logging.DEBUG,
                    format='%(asctime)s|%(levelname)s|%(message)s', datefmt='%Y-%m-%d %H:%M:%S')

class BankGUI():
    """Driver class for a command-line REPL interface to the Bank application"""

    def __init__(self):
        self._session = Session()
        # get bank from db
        self._bank = self._session.query(Bank).first()
        logging.debug("Loaded from bank.db")
        if not self._bank:
            self._bank = Bank()
            self._session.add(self._bank)
            self._session.commit()
            logging.debug("Saved to bank.db")

        self._window = tk.Tk()
        self._window.title("MY BANK")

        self._options_frame = tk.Frame(self._window)

        tk.Button(self._options_frame,
                  text="open account",
                  command=self._open_account).grid(row=1, column=1)
        tk.Button(self._options_frame,
                  text="summary",
                  command=self._summary).grid(row=1, column=2)
        tk.Button(self._options_frame,
                  text="select",
                  command=self._select).grid(row=1, column=3)
        tk.Button(self._options_frame,
                  text="add transaction",
                  command=self._add_transaction).grid(row=1, column=4)
        tk.Button(self._options_frame,
                  text="list transactions",
                  command=self._list_transactions).grid(row=1, column=5)
        tk.Button(self._options_frame,
                  text="interest and fees",
                  command=self._monthly_triggers).grid(row=1, column=6)
        tk.Button(self._options_frame,
                  text="quit",
                  command=self._quit).grid(row=1, column=7)

        self._list_frame = tk.Frame(self._window)
        self._options_frame.grid(row=0, column=1, columnspan=2)
        self._list_frame.grid(row=2, column=1, columnspan=1, sticky="w")

        self._window.mainloop()

        # establishes relationship to Accounts
        self._selected_account = None

        # show accounts immediately
        # FloatSpinbox(control_frame, step_size=5).pack()

        # i = 0
        # for account in self._bank.show_accounts():
        #     tk.Label(self._window, text=str(account)).grid(row=2+i,column=1)
        #     i += 1

        self._choices = {
            "1": self._open_account,
            "2": self._summary,
            "3": self._select,
            "4": self._add_transaction,
            "5": self._list_transactions,
            "6": self._monthly_triggers,
            "7": self._quit,
        }

    def _display_menu(self):
        print(f"""--------------------------------
Currently selected account: {self._selected_account}
Enter command
1: open account
2: summary
3: select account
4: add transaction
5: list transactions
6: interest and fees
7: quit""")

    def run(self):
        """Display the menu and respond to choices."""

        while True:
            self._display_menu()
            choice = input(">")
            action = self._choices.get(choice)
            # expecting a digit 1-7
            if action:
                action()
            else:
                # not officially part of spec since we don't give invalid options
                print("{0} is not a valid choice".format(choice))

    def _summary(self):                                                                           #****************************************
        # dependency on Account objects
        accounts = self._bank.show_accounts()
        print(accounts)
        i = 0
        for account in accounts:
            print(account)
            tk.Label(self._window, text=str(account)).grid(row=2+i,column=1)
            i += 1

    # def _save(self):
    #     with open("bank.pickle", "wb") as f:
    #         pickle.dump(self._bank, f)
    #     logging.debug("Saved to bank.pickle")

    def _quit(self):
        sys.exit(0)

    def _add_transaction(self):
        amount = None
        while amount is None:
            try:
                amount = Decimal(input("Amount?\n>"))
            except InvalidOperation:
                print("Please try again with a valid dollar amount.")

        date = None
        while not date:
            try:
                date = datetime.strptime(
                    input("Date? (YYYY-MM-DD)\n>"), "%Y-%m-%d").date()
            except ValueError:
                print("Please try again with a valid date in the format YYYY-MM-DD.")

        try:
            self._selected_account.add_transaction(amount, date, self._session)
        except AttributeError as err:
            print("This command requires that you first select an account.")
            print(err)
        except OverdrawError:
            print(
                "This transaction could not be completed due to an insufficient account balance.")
        except TransactionLimitError as ex:
            print(
                f"This transaction could not be completed because this account already has {ex.limit} transactions in this {ex.limit_type}.")
        except TransactionSequenceError as ex:
            print(f"New transactions must be from {ex.latest_date} onward.")

        self._session.commit()
        logging.debug("Saved to bank.db")

    def _open_account(self):
        acct_type = input("Type of account? (checking/savings)\n>")

        try:
            self._bank.add_account(acct_type, self._session)
        except OverdrawError:
            print(
                "This transaction could not be completed due to an insufficient account balance.")
        self._session.commit()
        logging.debug("Saved to bank.db")

    def _select(self):
        num = int(input("Enter account number\n>"))
        self._selected_account = self._bank.get_account(num)

    def _monthly_triggers(self):
        try:
            self._selected_account.assess_interest_and_fees(self._session)
            logging.debug("Triggered interest and fees")
        except AttributeError:
            print("This command requires that you first select an account.")
        except TransactionSequenceError as e:
            print(
                f"Cannot apply interest and fees again in the month of {e.latest_date.strftime('%B')}.")
        self._session.commit()
        logging.debug("Saved to bank.db")

    def _list_transactions(self):
        try:
            for t in self._selected_account.get_transactions():
                print(t)
        except AttributeError:
            print("This command requires that you first select an account.")


if __name__ == "__main__":
    # connect to the database
    # in general a connection string looks like...
    # dialect+driver://username:password@host:port/database
    engine = sqlalchemy.create_engine("sqlite:///bank.db")

    # creates SQL tables based on the OOP models
    # if the tables already exist, this does nothing (even if there was a change)
    Base.metadata.create_all(engine)

    # session factory
    Session = sessionmaker(bind=engine) 


    try:
        BankGUI().run()
    except Exception as e:
        print("Sorry! Something unexpected happened. Check the logs or contact the developer for assistance.")
        logging.error(str(e.__class__.__name__) + ": " + repr(str(e)))
