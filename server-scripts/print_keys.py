from treys import Deck, Card

deck = Deck()
for i in range(52):
    card = deck.draw(1)
    print(Card.int_to_pretty_str(card[0]), card)

mapping = {
    16787479: "spade_ten.png", 73730: "heart_two.png", 2102541: "spade_seven.png", 8423187: "club_nine.png",
    134253349: "club_king.png", 533255: "heart_five.png", 8394515: "heart_nine.png", 268442665: "spade_ace.png",
    139523: "heart_three.png", 268454953: "diamond_ace.png", 134236965: "diamong_king.png", "134224677": "spade_king.png",
    4199953: "spade_eight.png", 279045: "diamond_four.png", 4212241: "diamond_eight.png", 16783383: "spade_ten.png",
    4204049: "heart_eight.png", 8398611: "heart_nine.png", 2106637: "heart_seven.png", 33573149: "diamond_jack.png",
    1053707: "spade_six.png", 81922: "diamond_two.png", 8406803: "diamond_nine.png", 69634: "spade_two.png",
    147715: "diamond_three.png", 33560861: "spade_jack.png", 541447: "diamond_five.png", 67119647: "heart_queen.png",
    1057803: "heart_six.png", 33564957: "heart_jack.png", 529159: "spade_five.png", 557831: "club_five.png",
    67115551: "spade_queen.png", 16812055: "club_ten.png", 16795671: "diamond_ten.png", 2131213: "club_seven.png",
    1082379: "club_six.png", 33589533: "club_jack.png", 98306: "club_two.png", 135427: "spade_three.png",
    2114829: "diamond_seven.png", 134228773: "heart_king.png", 67127839: "diamond_queen.png", 67144223: "club_queen.png",
    268471337: "club_ace.png", 164099: "club_three.png", 295429: "club_four.png", 266757: "spade_four.png",
    268446761: "heart_ace.png", 270853: "heart_four.png", 4228626: "club_eight.png", 1065995: "diamond_six.png"
}