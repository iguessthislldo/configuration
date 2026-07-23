#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["pytest"]
# ///
"""Unit tests for pyigtd.cli module"""

import sys
from pathlib import Path
from dataclasses import dataclass

# Add lib to path
repo_root = Path(__file__).parent.parent.parent.resolve()
sys.path.insert(0, str(repo_root / 'lib'))

from pyigtd.cli import Cli, cli_field, cli_field_opt_pos, cli_call


@dataclass
class SampleApp(Cli):
    """Sample application for testing"""

    pos_req: int = cli_field(pos=True)
    pos_opt: str = cli_field_opt_pos(default='hi')
    opt: str = cli_field(opt=True)
    bool_opt1: bool = cli_field(opt=True, default=False)
    bool_opt2: bool = cli_field(opt=True, default=True)
    called_foo: bool = False
    called_bar: str | None = None

    @cli_call
    def foo(self):
        """Do foo"""
        self.called_foo = True

    @cli_call('--bar', '-b')
    def do_bar(self, arg: int):
        """Do bar"""
        self.called_bar = arg


class TestCliBasic:
    """Test basic Cli functionality"""

    def test_positional_required(self):
        t = SampleApp()
        t.parse_args(['123'])
        assert t.pos_req == 123
        assert isinstance(t.pos_req, int)

    def test_positional_optional_default(self):
        t = SampleApp()
        t.parse_args(['123'])
        assert t.pos_opt == 'hi'

    def test_positional_optional_provided(self):
        t = SampleApp()
        t.parse_args(['123', 'bye'])
        assert t.pos_opt == 'bye'

    def test_optional_flag_not_provided(self):
        t = SampleApp()
        t.parse_args(['123'])
        assert t.opt is None

    def test_optional_flag_provided(self):
        t = SampleApp()
        t.parse_args(['123', 'bye', '--opt', 'byeee'])
        assert t.opt == 'byeee'

    def test_bool_default_false(self):
        t = SampleApp()
        t.parse_args(['123'])
        assert t.bool_opt1 is False

    def test_bool_default_true(self):
        t = SampleApp()
        t.parse_args(['123'])
        assert t.bool_opt2 is True

    def test_bool_opt1_toggle(self):
        t = SampleApp()
        t.parse_args(['123', '--bool-opt1'])
        assert t.bool_opt1 is True

    def test_bool_opt2_toggle(self):
        t = SampleApp()
        t.parse_args(['123', '--bool-opt2'])
        assert t.bool_opt2 is False


class TestCliCalls:
    """Test cli_call decorated methods"""

    def test_cli_call_foo_not_called(self):
        t = SampleApp()
        t.parse_args(['123'])
        assert t.called_foo is False

    def test_cli_call_foo_called(self):
        t = SampleApp()
        t.parse_args(['123', '--foo'])
        assert t.called_foo is True

    def test_cli_call_bar_not_called(self):
        t = SampleApp()
        t.parse_args(['123'])
        assert t.called_bar is None

    def test_cli_call_bar_with_long_option(self):
        t = SampleApp()
        t.parse_args(['123', '--bar', '42'])
        assert t.called_bar == '42'

    def test_cli_call_bar_with_short_option(self):
        t = SampleApp()
        t.parse_args(['123', '-b', '99'])
        assert t.called_bar == '99'


class TestCliCombinations:
    """Test combinations of flags"""

    def test_pos_req_and_opt(self):
        t = SampleApp()
        t.parse_args(['123', 'bye', '--opt', 'byeee'])
        assert t.pos_req == 123
        assert t.pos_opt == 'bye'
        assert t.opt == 'byeee'
        assert t.called_foo is False
        assert t.called_bar is None

    def test_foo_and_bar_long(self):
        t = SampleApp()
        t.parse_args(['123', '--foo', '--bar', '$'])
        assert t.pos_req == 123
        assert t.pos_opt == 'hi'
        assert t.opt is None
        assert t.bool_opt1 is False
        assert t.bool_opt2 is True
        assert t.called_foo is True
        assert t.called_bar == '$'

    def test_foo_and_bar_short(self):
        t = SampleApp()
        t.parse_args(['123', '--foo', '-b', '$'])
        assert t.pos_req == 123
        assert t.pos_opt == 'hi'
        assert t.opt is None
        assert t.bool_opt1 is False
        assert t.bool_opt2 is True
        assert t.called_foo is True
        assert t.called_bar == '$'

    def test_bool_opt1_with_foo(self):
        t = SampleApp()
        t.parse_args(['123', '--bool-opt1', '--foo'])
        assert t.pos_req == 123
        assert t.pos_opt == 'hi'
        assert t.opt is None
        assert t.bool_opt1 is True
        assert t.bool_opt2 is True
        assert t.called_foo is True
        assert t.called_bar is None

    def test_bool_opt2_toggle_with_foo(self):
        t = SampleApp()
        t.parse_args(['123', '--foo', '--bool-opt2'])
        assert t.pos_req == 123
        assert t.pos_opt == 'hi'
        assert t.opt is None
        assert t.bool_opt1 is False
        assert t.bool_opt2 is False
        assert t.called_foo is True
        assert t.called_bar is None


class TestCliDefaults:
    """Test default values across multiple instances"""

    def test_multiple_instances_independent(self):
        """Ensure separate instances don't share state"""
        t1 = SampleApp()
        t1.parse_args(['123', '--foo'])

        t2 = SampleApp()
        t2.parse_args(['456'])

        assert t1.pos_req == 123
        assert t1.called_foo is True

        assert t2.pos_req == 456
        assert t2.called_foo is False

    def test_defaults_preserved_across_instances(self):
        """Ensure defaults are set correctly each time"""
        t1 = SampleApp()
        t1.parse_args(['123'])

        t2 = SampleApp()
        t2.parse_args(['456'])

        assert t1.pos_opt == 'hi'
        assert t2.pos_opt == 'hi'
        assert t1.bool_opt1 is False
        assert t2.bool_opt1 is False


if __name__ == "__main__":
    import pytest
    pytest.main([__file__, "-v"])
