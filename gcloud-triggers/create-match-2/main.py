import logging
import random
import uuid

import firebase_admin
from firebase_admin import credentials, firestore
from treys import Deck, Card

from firebase_admin import firestore

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Import your create_match function
# from your_module import create_match

# Initialize Firebase Admin SDK
firebase_admin.initialize_app()

# Define Firestore client
db = firestore.client()

def create_match(user_pair):
    try:
        match_id = str(uuid.uuid4())
        random.shuffle(user_pair)  # Randomly assign the order of players
        player1, player2 = user_pair

        user1_ref = db.collection('users').document(player1)
        user2_ref = db.collection('users').document(player2)

        # Fetch user ratings
        user1_doc = user1_ref.get()
        user2_doc = user2_ref.get()

        if not user1_doc.exists or not user2_doc.exists:
            logger.error(f"One of the users does not exist: {user_pair}")
            return

        user1_rating = user1_doc.get('rating')
        user2_rating = user2_doc.get('rating')

        if user1_doc.get('pot') == 0:
            player1_pot = 0.01 * user1_rating
        else:
            player1_pot = user1_doc.get('pot')

        if user2_doc.get('pot') == 0:
            player2_pot = 0.01 * user2_rating
        else:
            player2_pot = user2_doc.get('pot')

        # Calculate pots based on ratings and initial raise
        player1_raise = 0.01 * player1_pot
        player2_raise = 0.01 * player2_pot

        # Determine who has initial action (randomly choose one player to have the first action)
        initial_action = random.choice(['player1', 'player2'])
        if initial_action == 'player1':
            player2_raise *= 2
        else:
            player1_raise *= 2

        player1_pot -= player1_raise
        player2_pot -= player2_raise

        # Generate unique cards for players
        deck = Deck()
        player1_cards = deck.draw(2)
        player2_cards = deck.draw(2)
        logger.info(f"Cards dealt. Player 1 has {[Card.int_to_pretty_str(card) for card in player1_cards]}. Player 2 has {[Card.int_to_pretty_str(card) for card in player2_cards]}")

        match_data = {
            'user_ids': user_pair,
            'created_at': firestore.SERVER_TIMESTAMP,
            'initial_action': initial_action,
            'player1': {
                'id': player1,
                'cards': player1_cards,
                'raise': player1_raise,
                'pot': player1_pot,
                'fold': False,
                'has_action': initial_action == 'player1',
                'action': None,
                'prev_actions': [],
                'hand_type': ''
            },
            'player2': {
                'id': player2,
                'cards': player2_cards,
                'raise': player2_raise,
                'pot': player2_pot,
                'fold': False,
                'has_action': initial_action == 'player2',
                'action': None,
                'prev_actions': [],
                'hand_type': ''
            },
            'flop': deck.draw(3),
            'turn': deck.draw(1),
            'river': deck.draw(1),
            'winner': None,
            'round': 0,
            'full': True
        }

        # Update each user's document with the match_id and their player role
        user1_ref.update({
            'rating': user1_doc.get('rating') + user1_doc.get('pot') - player1_pot - player1_raise,
            'searchingForMatch': False,
            'inMatch': True,
            'newMatch': False,
            'match_id': match_id,
            'pot': 0
        })

        user2_ref.update({
            'rating': user2_doc.get('rating') - user2_doc.get('pot') - player1_pot - player1_raise,
            'searchingForMatch': False,
            'inMatch': True,
            'newMatch': False,
            'match_id': match_id,
            'pot': 0
        })

        # Create a new document in the matches collection
        matches_ref = db.collection('matches').document(match_id)
        matches_ref.set(match_data)

        logger.info(f"Match created with ID: {match_id} for users: {user_pair}, player1: {player1}, player2: {player2}")
    except Exception as e:
        logger.error(f"Error in create_match: {e}", exc_info=True)

# Define the Cloud Function
def firestore_trigger(event, context):
    """Triggered by a change to a Firestore document."""
    # Get the updated document data
    new_value = event.get('value', {}).get('fields', {})
    
    # Extract the 'searching' field from the new value
    if 'searching' in new_value:
        searching = new_value['searching']['arrayValue']['values']
        
        # Convert Firestore array to a Python list
        searching_list = [item['stringValue'] for item in searching]
        
        # Ensure there are at least two elements in the list
        if len(searching_list) >= 2:
            user_pair = searching_list[:2]
            create_match(user_pair)
            db.collection('searching').document('searching').update({'searching': [] if len(searching_list) == 2 else searching_list[2:]})

