from flask import (
    Blueprint, flash, g, jsonify, redirect, render_template, request, url_for
)
from werkzeug.exceptions import abort
from niner_repo.auth import login_required
from niner_repo.db import get_db

bp = Blueprint('transactions', __name__)

@bp.route('/api/finance/summary')
@login_required
def get_finance_summary():
    """Get financial summary including costs and savings breakdown."""
    db = get_db()
    
    try:
        # Get total income
        income = db.execute(
            'SELECT SUM(amount) as total FROM income WHERE user_id = ?',
            (g.user['id'],)
        ).fetchone()
        total_income = income['total'] if income['total'] else 0

        # Get total expenses
        expenses = db.execute(
            'SELECT SUM(amount) as total FROM expenses WHERE user_id = ?',
            (g.user['id'],)
        ).fetchone()
        total_expenses = expenses['total'] if expenses['total'] else 0

        # Calculate total savings
        total_savings = total_income - total_expenses

        # Get expense breakdown by category
        expense_breakdown = db.execute(
            '''SELECT category, SUM(amount) as total 
               FROM expenses 
               WHERE user_id = ? 
               GROUP BY category
               ORDER BY total DESC''',
            (g.user['id'],)
        ).fetchall()

        # Get income breakdown by source
        income_breakdown = db.execute(
            '''SELECT source as category, SUM(amount) as total 
               FROM income 
               WHERE user_id = ? 
               GROUP BY source
               ORDER BY total DESC''',
            (g.user['id'],)
        ).fetchall()

        # Prepare the response
        response = {
            'summary': {
                'total_income': total_income,
                'total_expenses': total_expenses,
                'total_savings': total_savings
            },
            'expenses_breakdown': [dict(row) for row in expense_breakdown],
            'income_breakdown': [dict(row) for row in income_breakdown]
        }

        return jsonify(response)

    except Exception as e:
        # Log the error (you should set up proper logging)
        print(f"Error in get_finance_summary: {str(e)}")
        return jsonify({'error': 'Failed to fetch financial data'}), 500

@bp.route('/graphs/visuals')
@login_required
def show_visuals():
    """Show the financial split view."""
    return render_template('graphs/visuals.html')
