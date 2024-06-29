import logging
import firebase_admin
from firebase_admin import firestore
from treys import Evaluator, Card

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize the Firebase Admin SDK
firebase_admin.initialize_app()

# Initialize Firestore client
db = firestore.client()

# Initialize the evaluator
evaluator = Evaluator()

def get_hand_type(hand_strength):
    hand_types = {
        0: 'Royal Flush',
        1: 'Straight Flush',
        2: 'Four of a Kind',
        3: 'Full House',
        4: 'Flush',
        5: 'Straight',
        6: 'Three of a Kind',
        7: 'Two Pair',
        8: 'One Pair',
        9: 'High Card'
    }
    return hand_types.get(hand_strength, 'Unknown')

def evaluate_hands(match_data):
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

def proceed_to_next_round(match_id, match_data):
    try:
        update_data = {}
        player1_strength, player2_strength = None, None

        # Evaluate hands if not pre-flop and not game over
        if match_data['round'] != 0 and match_data['round'] != 4:
            player1_hand_type, player2_hand_type, player1_strength, player2_strength = evaluate_hands(match_data)
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
            logger.info(f"Now in Flop {match_id}: Flop is {[Card.int_to_pretty_str(match_data['flop'][i]) for i in range(3)]}")
        elif match_data['round'] == 1:
            update_data['round'] = 2
            logger.info(f"Now in Turn {match_id}: Turn is {Card.int_to_pretty_str(match_data['turn'][0])}")
        elif match_data['round'] == 2:
            update_data['round'] = 3
            logger.info(f"Now in River {match_id}: River is {Card.int_to_pretty_str(match_data['river'][0])}")
        elif match_data['round'] == 3:
            update_data['round'] = 4
            logger.info(f"Game has ended! Winner is {update_data['winner']}")
        elif match_data['round'] == 4:
            winner = match_data['winner']
            loser = 'player1' if winner == 'player2' else 'player2'
            update_data[f'{winner}.pot'] = match_data[winner]['pot'] + match_data[winner]['raise'] + match_data[loser]['raise']
            update_data[f'{winner}.raise'] = 0
            update_data[f'{loser}.raise'] = 0
            logger.info(f"Player 1 new pot size is {match_data[winner]['pot']}. Player 2 new pot size is {match_data[loser]['pot']}")

        if match_data['player1']['fold'] or match_data['player2']['fold'] or match_data['round'] == 3:
            update_data['player1.has_action'] = False
            update_data['player2.has_action'] = False
        else:
            initial_action = match_data['initial_action']
            update_data['player1.has_action'] = initial_action == 'player1'
            update_data['player2.has_action'] = initial_action == 'player2'

        db.collection('matches').document(match_id).update(update_data)
    except Exception as e:
        logger.error(f"Error in proceed_to_next_round: {e}", exc_info=True)

def process_action(match_id, match_data):
    try:
        update_data = {}
        player = 'player1' if match_data['player1']['has_action'] else 'player2'
        opponent = 'player1' if player == 'player2' else 'player2'
        action = match_data[player]['action']
        opponentRaise = match_data[opponent]['raise']
        playerRaise = match_data[player]['raise']


        update_data[f"{player}.has_action"] = False
        update_data[f"{player}.action"] = None
        update_data[f"{player}.prev_actions"] = match_data[player]['prev_actions'] + action
        if action[0] == "call":
            update_data[f"{player}.raise"] = opponentRaise
            update_data[f"{player}.pot"] = match_data[player]['pot'] - (opponentRaise - match_data[player]['raise'])
            if match_data['initial_action'] == player:
                update_data[f"{opponent}.has_action"] = True
        elif action[0] == "raise" and action[1] is not None:
            if action[1] + playerRaise <= opponentRaise:
                logger.info("Raise amount is less than opponent's raise.")
            else:
                update_data[f"{player}.raise"] = playerRaise + action[1]
                update_data[f"{player}.pot"] = match_data[player]['pot'] - action[1]
                update_data[f"{opponent}.has_action"] = True
        elif action[0] == "fold":
            update_data[f"{player}.fold"] = True
        db.collection('matches').document(match_id).update(update_data)

    except Exception as e:
        logger.error(f"Error in process_action: {e}", exc_info=True)

def firestore_trigger(event, context):
    resource_string = context.resource
    logger.info(f"Function triggered by change to: {resource_string}")

    # Get the updated document
    match_id = context.resource.split('/')[-1]
    match_data = db.collection('matches').document(match_id).get().to_dict()

    if match_data['player1']['action'] is not None or match_data['player2']['action'] is not None:
        process_action(match_id, match_data)

    # Check if neither player has action
    if not match_data['player1']['has_action'] and not match_data['player2']['has_action']:
        proceed_to_next_round(match_id, match_data)
