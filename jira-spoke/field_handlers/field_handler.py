# Copyright 2021 Broadcom.  All Rights Reserved.


class FieldHandler:

    def __init__(self, field_name=None):

        #Not sure why we are passing field_name but don't want to break backwards compatibility so leaving it for now

        self.field_name  = field_name
        #Field handler is created before we have a connection object
        self.connection = None

    def className(self)
        return self.__class__.__name__
    
    def transformIn(self, artifact):
        #Coming in, you don't have the object (when creating) but you do on update, thus we send in the value from the other system
        # We could send in the other (maybe Rally) object but that would not be that useful
        return value

    
    def transformOut(self, artifact):
        #When transforming out, we have the object in our hand
        return self.connection.getValue(artifact, self.field_name)


    def readConfig(self, fh_info):
        if not fh_info or len(fh_info) == 0:
            problem = f"Field or FieldName tag for #{self.className()} must be present in the FieldHandler configuration"
            raise ConfigurationError(problem)
        for item, value in fh_info.items():
            if item == "FieldName" or item == "Field":
                self.field_name = value if value != {} else None

        if self.field_name is None:
            problem = f"Field or FieldName for {self.className()} must not be empty"
            raise ConfigurationError(problem)

    def fieldnameElementCheck(self, fh_info):
        for item, value in fh_info.items():
            if item not in ["Field", "FieldName"]:
                problem = f"Element {item} not expected in {self.className()} config"
                raise ConfigurationError(problem)


class RallyFieldHandler(FieldHandler): pass
class OtherFieldHandler(FieldHandler): pass
