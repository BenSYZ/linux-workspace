import gdb
import sys

class FilteredBtCommand(gdb.Command):
    """Print a backtrace filtered via string evaluation."""

    def __init__(self):
        # Registers the command as 'fbt' inside the maintenance user class
        super(FilteredBtCommand, self).__init__("bt", gdb.COMMAND_USER)

    def invoke(self, arg, from_tty):
        # Capture the original raw string output of the 'bt' command
        raw_bt = gdb.execute("backtrace", to_string=True)

        # Split the text output line by line
        lines = raw_bt.splitlines()

        for line in lines:
            # Print matching lines back out to GDB's stdout
            print(line)

# Instantiate the command object to bind it to the CLI
FilteredBtCommand()
