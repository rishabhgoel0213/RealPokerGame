from treys import Deck, Card

deck = Deck()
for i in range(52):
    card = deck.draw(1)
    print(Card.int_to_pretty_str(card[0]), card)