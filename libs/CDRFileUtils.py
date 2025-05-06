"""
A few utils to work with CDR File
"""
import csv
from dataclasses import dataclass

@dataclass
class CallRecord:
    call_type: str
    served_msisdn: str
    second_msisdn: str
    start_time: str
    end_time: str


class CDRFileUtils:
    """
    A few utils to work with CDR File
    """
    def parse_csv_cdr(self, cdr_path: str) -> list[dict]:
        res = []
        with open(cdr_path, 'r') as f:
            reader = csv.reader(f)
            for row in reader:
                if len(row) == 5:
                    res.append(
                        CallRecord(
                            call_type = row[0], 
                            served_msisdn = row[1], 
                            second_msisdn = row[2], 
                            start_time = row[3],
                            end_time = row[4])
                            )
                else: 
                    raise AssertionError(f"Wrong number of fields in line!\nExpected: 5\nGot: {len(row)}")
        return res