from typing import Any, Optional

import pandas as pd
from great_expectations.core.expectation_configuration import ExpectationConfiguration
from great_expectations.execution_engine import PandasExecutionEngine, SqlAlchemyExecutionEngine
from great_expectations.expectations.expectation import ColumnMapExpectation
from great_expectations.expectations.metrics import (
    ColumnMapMetricProvider,
    column_condition_partial,
)
try:
    import sqlalchemy as sa  # noqa: TID251
except ImportError:
    sa = None

# This class defines a Metric to support your Expectation.
# For most ColumnMapExpectations, the main business logic for calculation will live in this class.
class ColumnValuesListMembers(ColumnMapMetricProvider):
    """Class definition for list members checking metric."""

    # This is the id string that will be used to reference your metric.
    condition_metric_name = "column_values.list_members"
    condition_value_keys = ("list_members",)

    # This method implements the core logic for the PandasExecutionEngine
    @column_condition_partial(engine=PandasExecutionEngine)
    def _pandas(
        cls, column: pd.core.series.Series, list_members: set, **kwargs
    ) -> bool:
        """Core logic for list member checking metric on a
        pandas execution engine.

        Args:
            column (pd.core.series.Series): Pandas column to be evaluated.
            list_members (set): Expected list members.
        Returns:
            bool: Whether or not the column values have the expected list members.
        """
        return column.apply(lambda x: cls._check_list_members(x, list_members))

    @staticmethod
    def _check_list_members(cell: Any, list_members: set) -> bool:
        """Check if a cell is a list, and if it has the expected members.

        Args:
            cell (Any): Individual cell to be evaluated.
            list_members (set): Expected list members.

        Returns:
            bool: Whether or not the cell is a list with the expected members.
        """
        if not isinstance(cell, list):
            return False
        if not all(item in list_members for item in cell):
            return False
        return True
    @column_condition_partial(engine=SqlAlchemyExecutionEngine)
    def _sqlalchemy(cls, column, list_members, **kwargs):
        return cls._sqlalchemy_impl(column, list_members, **kwargs)

    @staticmethod
    def _sqlalchemy_impl(column, list_members, **kwargs):
        allowed_values_array = sa.func.array_construct(*list_members)
        return sa.func.array_size(column) == sa.func.array_size(sa.func.array_intersection(column, allowed_values_array))
    
# This class defines the Expectation itself
class ExpectColumnValuesToHaveListMembers(ColumnMapExpectation):
    """Expect the list in column values to have certain members."""

    # These examples will be shown in the public gallery.
    # They will also be executed as unit tests for your Expectation.
    examples = [
        {
            "data": {
                "a": [["a", "b", "a", "b"]],
                "b": [["a", "b", "c", "d"]],
            },
            "tests": [
                {
                    "title": "positive_test_with_a_and_b",
                    "exact_match_out": False,
                    "include_in_gallery": True,
                    "in": {"column": "a", "list_members": {"a", "b"}},
                    "out": {"success": True},
                },
                {
                    "title": "negative_test_with_a_b_c_d",
                    "exact_match_out": False,
                    "include_in_gallery": True,
                    "in": {"column": "b", "list_members": {"a", "b"}},
                    "out": {"success": False},
                },
            ],
        }
    ]

    # This is the id string of the Metric used by this Expectation.
    # For most Expectations, it will be the same as the `condition_metric_name` defined in your Metric class above.
    map_metric = "column_values.list_members"

    # This is a list of parameter names that can affect whether the Expectation evaluates to True or False
    success_keys = ("list_members",)

    # This dictionary contains default values for any parameters that should have default values
    default_kwarg_values = {}

    def validate_configuration(
        self, configuration: Optional[ExpectationConfiguration] = None
    ) -> None:
        """
        Validates that a configuration has been set, and sets a configuration if it has yet to be set. Ensures that
        necessary configuration arguments have been provided for the validation of the expectation.

        Args:
            configuration (OPTIONAL[ExpectationConfiguration]): \
                An optional Expectation Configuration entry that will be used to configure the expectation
        Returns:
            None. Raises InvalidExpectationConfigurationError if the config is not validated successfully
        """

        super().validate_configuration(configuration)
        configuration = configuration or self.configuration

    # This object contains metadata for display in the public Gallery
    library_metadata = {
        "tags": [],  # Tags for this Expectation in the Gallery
        "contributors": [  # Github handles for all contributors to this Expectation.
            "@BWMac",  # Don't forget to add your github handle here!
        ],
    }


if __name__ == "__main__":
    ExpectColumnValuesToHaveListMembers().print_diagnostic_checklist()
