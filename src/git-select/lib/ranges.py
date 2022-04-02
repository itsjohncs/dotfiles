import re


def _int_or_none(text):
    if text == "":
        return None
    else:
        return int(text)


class Range:
    """An inclusive range of indices."""

    RANGE_RE = re.compile(
        r"(?P<index>0|[1-9][0-9]*)|"
        r"(?P<start>|0|[1-9][0-9]*):(?P<end>|0|[1-9][0-9]*)"
    )

    def __init__(self, start, end):
        self.start = start
        self.end = end

    def __str__(self):
        return f"[{self.start}, {self.end}]"

    def extract(self, lst):
        start = 0 if self.start is None else self.start
        end = len(lst) if self.end is None else self.end + 1

        if start >= len(lst) or end > len(lst):
            raise IndexError()

        return lst[start:end]

    @classmethod
    def parse(cls, text):
        match = cls.RANGE_RE.match(text)
        if match:
            if match.group("index"):
                return cls(int(match.group("index")), int(match.group("index")))
            else:
                return cls(
                    _int_or_none(match.group("start")), _int_or_none(match.group("end"))
                )

        raise ValueError(f"invalid range specifier: {text!r}")
