from app.entrypoints.cli import main


def test_cli_prints_normalized(capsys):
    assert main(["1", "3"]) == 0
    assert capsys.readouterr().out == "0.000 1.000\n"


def test_cli_rejects_bad_input():
    assert main(["x"]) == 2
