import logging
import time

import firebase_admin
from firebase_admin import credentials, firestore
from treys import Evaluator, Card

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Set the environment variable for Firestore (ensure this path is correct)
cred = credentials.Certificate("/opt/thisispoker/serviceAccountKey.json")
firebase_admin.initialize_app(cred)

# Initialize Firestore client
db = firestore.client()

# Initialize the evaluator
evaluator = Evaluator()

def get_hand_type(hand_strength):
    if hand_strength == 0:
        return 'Royal Flush'
    elif hand_strength == 1:
        return 'Straight Flush'
    elif hand_strength == 2:
        return 'Four of a Kind'
    elif hand_strength == 3:
        return 'Full House'
    elif hand_strength == 4:
        return 'Flush'
    elif hand_strength == 5:
        return 'Straight'
    elif hand_strength == 6:
        return 'Three of a Kind'
    elif hand_strength == 7:
        return 'Two Pair'
    elif hand_strength == 8:
        return 'One Pair'
    elif hand_strength == 9:
        return 'High Card'
    return 'Unknown'


def evaluate_hands(match_data, match_id):
    try:
        player1_cards = [Card.new(Card.int_to_str(card)) for card in match_data['player1']['cards']]
        player2_cards = [Card.new(Card.int_to_str(card)) for card in match_data['player2']['cards']]
        round_names = ['flop', 'turn', 'river']
        board = []
        for i in range(match_data['round']):
            board += match_data[round_names[i]]
        board = [Card.new(Card.int_to_str(card)) for card in board]
    except KeyError as e:
        logger.error(f"KeyError during card conversion: {e}")
        raise

    player1_strength = evaluator.evaluate(board, player1_cards)
    player2_strength = evaluator.evaluate(board, player2_cards)

    player1_hand_type = get_hand_type(evaluator.get_rank_class(player1_strength))
    player2_hand_type = get_hand_type(evaluator.get_rank_class(player2_strength))

    return player1_hand_type, player2_hand_type, player1_strength, player2_strength


def proceed_to_next_round():
    try:
        matches_ref = db.collection('matches')
        matches = matches_ref.stream()

        for match in matches:
            print(match.id)
            match_data = match.to_dict()
            player1_action = match_data['player1']['has_action']
            player2_action = match_data['player2']['has_action']

            if not player1_action and not player2_action:
                update_data = {}

                # Evaluate hands
                if match_data['round'] != 0 and match_data['round'] != 4:
                    player1_hand_type, player2_hand_type, player1_strength, player2_strength = evaluate_hands(
                        match_data,
                        match.id)
                    update_data['player1.hand_type'] = player1_hand_type
                    update_data['player2.hand_type'] = player2_hand_type

                if match_data['round'] == 3:
                    if match_data['player1']['fold']:
                        update_data['winner'] = 'player2'
                    elif match_data['player2']['fold']:
                        update_data['winner'] = 'player1'
                    elif player1_strength < player2_strength:
                        update_data['winner'] = 'player1'
                    elif player2_strength < player1_strength:
                        update_data['winner'] = 'player2'
                    else:
                        update_data['winner'] = 'draw'

                if match_data['round'] == 0:
                    update_data['round'] = 1
                    logger.info(
                        f"Now in Flop {match.id}: Flop is {[Card.int_to_pretty_str(match_data['flop'][i]) for i in range(3)]}")
                elif match_data['round'] == 1:
                    update_data['round'] = 2
                    logger.info(f"Now in Turn {match.id}: Turn is {Card.int_to_pretty_str(match_data['turn'][0])}")
                elif match_data['round'] == 2:
                    update_data['round'] = 3
                    logger.info(f"Now in River {match.id}: River is {Card.int_to_pretty_str(match_data['river'][0])}")
                elif match_data['round'] == 3:
                    update_data['round'] = 4
                    logger.info(f"Game has ended! Winner is {update_data['winner']}")
                elif match_data['round'] == 4:
                    winner = match_data['winner']
                    loser = 'player1' if winner == 'player2' else 'player2'
                    update_data[winner + '.pot'] = match_data[winner]['pot'] + match_data[winner]['raise'] + match_data[loser]['raise']
                    update_data[winner + '.raise'] = 0
                    update_data[loser + '.raise'] = 0
                    logger.info(f"Player 1 new pot size is {match_data[winner]['pot']}. Player 2 new pot size is {match_data[loser]['pot']}")

                # Determine who initially had the action and give it back to them
                if match_data['player1']['fold'] or match_data['player2']['fold'] or match_data['round'] == 3:
                    update_data['player1.has_action'] = False
                    update_data['player2.has_action'] = False
                else:
                    initial_action = match_data['initial_action']
                    update_data['player1.has_action'] = initial_action == 'player1'
                    update_data['player2.has_action'] = initial_action == 'player2'

                # Update the match document
                matches_ref.document(match.id).update(update_data)
    except Exception as e:
        logger.error(f"Error in proceed_to_next_round: {e}", exc_info=True)

def monitor_match():
    logger.info("Monitoring matches...")
    try:
        while True:
            proceed_to_next_round()
            time.sleep(5)  # Check every 5 seconds
    except Exception as e:
        logger.error(f"Error in monitor_match: {e}", exc_info=True)


if __name__ == "__main__":
    monitor_match()