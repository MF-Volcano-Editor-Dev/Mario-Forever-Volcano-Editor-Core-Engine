class_name QuestionBlockItemAbundant extends QuestionBlockItem

## A type of [QuestionBlockItem] that contains large amount of [member QuestionBlockItem.default] items.
##
## 

## Limitation of getting items.[br]
## * Time(0): In given times, items can be hit out, and once the time is up, the item is the last one.[br]
## * Amount(1): Items are given with specific amounts.
@export_enum("Time", "Amount") var limitation: int
## Time of getting items. See [member limitation].
@export_range(0, 120, 0.001, "suffix:s") var time: float = 6
## Amount of items the character can get. See [member limitation].
@export_range(0, 999) var amount: int = 10
