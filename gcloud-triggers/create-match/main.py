import logging
import random
import uuid

import firebase_admin
from firebase_admin import credentials, firestore
from treys import Deck, Card

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Firebase Admin SDK
cred = credentials.ApplicationDefault()  # Uses the default service account
firebase_admin.initialize_app(cred)
db = firestore.client()

def check_for_matching_users():
    try:
        users_ref = db.collection('users')
        query = users_ref.where('searchingForMatch', '==', True)
        docs = query.stream()

        matching_users = []
        for doc in docs:
            matching_users.append(doc.id)

        return matching_users
    except Exception as e:
        logger.error(f"Error in check_for_matching_users: {e}", exc_info=True)

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

def find_or_create_match(user_id):
    try:
        # Find an existing match that is not full
        matches_ref = db.collection('matches')
        user_ref = db.collection('users').document(user_id)
        # Fetch user ratings
        user_doc = user_ref.get()
        if not user_doc.exists:
            logger.error(f"User does not exist: {user_id}")
            return

        rating = user_doc.get('rating')
        pot = 0.01 * rating
        if user_doc.get('pot') != 0:
            pot = user_doc.get('pot')
        user_raise = 0.02 * pot
        pot -= user_raise
        
        non_full_matches = matches_ref.where('full', '==', False).stream()
        for match in non_full_matches:
            match_data = match.to_dict()
            match_id = match.id
            # Join the match
            db.collection('matches').document(match_id).update({
                'player2.id': user_id,
                'player2.has_action': True,
                'player2.fold': False,
                'player2.raise': 0,
                'player2.pot': 0,
                'player2.action': None,
                'player2.prev_actions': [],
                'full': True
            })
            user_ref = db.collection('users').document(user_id)
            user_ref.update({
                'searchingForMatch': False,
                'inMatch': True,
                'newMatch': False,
                'match_id': match_id
            })
            return match_id

        # No available match found, create a new one
        deck = Deck()
        player1_cards = deck.draw(2)
        player2_cards = deck.draw(2)
        logger.info(f"Cards dealt. Player 1 has {[Card.int_to_pretty_str(card) for card in player1_cards]}. Player 2 has {[Card.int_to_pretty_str(card) for card in player2_cards]}")

        new_match_ref = db.collection('matches').add({
            'player1': {
                'id': user_id,
                'cards': player1_cards,
                'has_action': False,
                'fold': False,
                'raise': 0,
                'pot': 0,
                'action': None,
                'prev_actions': []
            },
            'player2': {
                'cards': player2_cards
            },
            'flop': deck.draw(3),
            'turn': deck.draw(1),
            'river': deck.draw(1),
            'round': 0,
            'full': False
        })
        user_ref = db.collection('users').document(user_id)
        user_ref.update({
            'searchingForMatch': False,
            'inMatch': True,
            'newMatch': False,
            'match_id': new_match_ref[1].id
        })
        return new_match_ref[1].id

    except Exception as e:
        logger.error(f"Error in find_or_create_match: {e}", exc_info=True)
        return None

def on_user_update(event, context):
    searchingForMatch = False
    user_id = context.resource.split('/')[-1]
    
    if not event["value"]["fields"]["inMatch"]["booleanValue"]:
        user_data = db.collection('users').document(user_id).get().to_dict()
        searching_users = db.collection('searching').document('searching').get().to_dict()
        if not user_data['inMatch']:
            match_id = user_data['match_id']
            user_ref = db.collection('users').document(user_id)
            searching_ref = db.collection('searching').document('searching')
            match_ref = db.collection('matches').document(match_id)
            match_doc = match_ref.get()
            if match_doc.exists:
                user_doc = match_doc.get('player1') if match_doc.get('player1').get('id') == user_id else match_doc.get('player2')
            else:
                user_doc = {'pot': 0}

            if user_data.get('newMatch'):
                searchingForMatch = True
                user_ref.update({
                    'match_id': None,
                    'newMatch': False,
                    'searchingForMatch': True,
                    'pot': user_doc.get('pot')
                })
                searching_ref.update({
                    'searching': list(set(searching_users['searching'] + [user_id]))
                })

            else:
                user_ref.update({
                    'rating': user_data['rating'] + user_doc.get('pot'),
                    'match_id': None,
                    'searchingForMatch': False,
                    'pot': 0
                })

            logger.info(f"Updated user document {user_id} to adjust rating/pot")

            # Delete the match document
            if match_doc.exists:
                opponent_doc = db.collection('users').document(match_doc.get('player2').get('id')).get().to_dict() if match_doc.get('player1').get('id') == user_id else db.collection('users').document(match_doc.get('player2').get('id')).get().to_dict()
                if opponent_doc['match_id'] is None or opponent_doc['match_id'] != match_id:
                    match_ref.delete()
                    logger.info(f"Deleted match with ID: {match_id}")

    # if searchingForMatch:
    #     user_doc = db.collection('users').document(user_id).get()
    #     if user_doc.exists and user_doc.get('searchingForMatch'):
    #         match_id = find_or_create_match(user_id)
    #         if match_id:
    #             logger.info(f"User {user_id} joined match {match_id}")

# Main entry point for the Cloud Function
def main(event, context):
    on_user_update(event, context)
